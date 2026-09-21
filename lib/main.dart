import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.system);

const List<String> kStatuses = [
  'Куплен',
  'В ремонте',
  'Готов к продаже',
  'На продаже',
  'Продан',
];

const List<String> kExpenseCategories = [
  'Запчасти',
  'Работа / ремонт',
  'Мойка / химчистка',
  'Страховка',
  'Топливо',
  'Оформление / ГИБДД',
  'Комиссия',
  'Прочее',
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  themeNotifier.value = await Storage.loadTheme();
  runApp(const AutoProfitApp());
}

class AutoProfitApp extends StatelessWidget {
  const AutoProfitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Авто Профит',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: mode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
class Car {
  String id;
  String make;
  String model;
  String year;
  String vin;
  String plate;
  String mileage;
  String purchasePrice;
  String purchaseDate;
  String status;
  String seller;
  String sellerPhone;
  String sellerAddress;
  String notes;
  String salePrice;
  String saleDate;
  List<Expense> expenses;
  List<String> photos;

  Car({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.vin,
    required this.plate,
    required this.mileage,
    required this.purchasePrice,
    required this.purchaseDate,
    required this.status,
    required this.seller,
    required this.sellerPhone,
    required this.sellerAddress,
    required this.notes,
    required this.salePrice,
    required this.saleDate,
    required this.expenses,
    required this.photos,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: (json['id'] ?? '') as String,
      make: (json['make'] ?? '') as String,
      model: (json['model'] ?? '') as String,
      year: (json['year'] ?? '') as String,
      vin: (json['vin'] ?? '') as String,
      plate: (json['plate'] ?? '') as String,
      mileage: (json['mileage'] ?? '') as String,
      purchasePrice: (json['purchasePrice'] ?? '') as String,
      purchaseDate: (json['purchaseDate'] ?? '') as String,
      status: (json['status'] ?? 'Куплен') as String,
      seller: (json['seller'] ?? '') as String,
      sellerPhone: (json['sellerPhone'] ?? '') as String,
      sellerAddress: (json['sellerAddress'] ?? '') as String,
      notes: (json['notes'] ?? '') as String,
      salePrice: (json['salePrice'] ?? '') as String,
      saleDate: (json['saleDate'] ?? '') as String,
      expenses: ((json['expenses'] ?? []) as List)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList(),
      photos: ((json['photos'] ?? []) as List)
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'make': make,
        'model': model,
        'year': year,
        'vin': vin,
        'plate': plate,
        'mileage': mileage,
        'purchasePrice': purchasePrice,
        'purchaseDate': purchaseDate,
        'status': status,
        'seller': seller,
        'sellerPhone': sellerPhone,
        'sellerAddress': sellerAddress,
        'notes': notes,
        'salePrice': salePrice,
        'saleDate': saleDate,
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'photos': photos,
      };

  double get purchase =>
      double.tryParse(purchasePrice.replaceAll(',', '.')) ?? 0;

  double get sale =>
      double.tryParse(salePrice.replaceAll(',', '.')) ?? 0;

  double get expensesTotal =>
      expenses.fold(0, (sum, item) => sum + item.amount);

  double get invested => purchase + expensesTotal;

  double get profit => sale - invested;

  bool get isSold => sale > 0;

  DateTime? get purchaseDateTime {
    if (purchaseDate.isEmpty) return null;
    return DateTime.tryParse(purchaseDate);
  }

  DateTime? get saleDateTime {
    if (saleDate.isEmpty) return null;
    return DateTime.tryParse(saleDate);
  }

  int get daysInStock {
    final start = purchaseDateTime;
    if (start == null) return 0;
    final end = saleDateTime ?? DateTime.now();
    return end.difference(start).inDays;
  }
}

class Expense {
  String id;
  String category;
  double amount;
  String note;

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.note,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: (json['id'] ?? '') as String,
      category: (json['category'] ?? 'Прочее') as String,
      amount: ((json['amount'] ?? 0) as num).toDouble(),
      note: (json['note'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'amount': amount,
        'note': note,
      };
}

class Storage {
  static const _key = 'cars_v1';
  static const _themeKey = 'theme_mode_v1';

  static Future<List<Car>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Car.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<Car> cars) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(cars.map((c) => c.toJson()).toList()),
    );
  }

  static Future<ThemeMode> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeKey);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await prefs.setString(_themeKey, raw);
  }
}

String newId() => DateTime.now().microsecondsSinceEpoch.toString();

String money(double value) {
  final f = NumberFormat('#,##0');
  return '${f.format(value).replaceAll(',', ' ')} ₽';
}

String moneyShort(double value) {
  if (value.abs() >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)} млн ₽';
  }
  if (value.abs() >= 1000) {
    return '${(value / 1000).toStringAsFixed(0)} тыс ₽';
  }
  return '${value.toStringAsFixed(0)} ₽';
}

String formatDate(DateTime d) => DateFormat('dd.MM.yyyy').format(d);

String todayIso() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
class MonthStat {
  final String label;
  final double profit;
  final int count;
  MonthStat({
    required this.label,
    required this.profit,
    required this.count,
  });
}

class CategoryStat {
  final String name;
  final double amount;
  CategoryStat({required this.name, required this.amount});
}

class Analytics {
  final List<Car> cars;

  Analytics(this.cars);

  List<Car> get soldCars => cars.where((c) => c.isSold).toList();
  List<Car> get stockCars => cars.where((c) => !c.isSold).toList();

  // === ЗАКУП И РАСХОДЫ ===
  double get totalPurchase =>
      cars.fold(0, (s, c) => s + c.purchase);

  double get totalPurchaseStock =>
      stockCars.fold(0, (s, c) => s + c.purchase);

  double get totalPurchaseSold =>
      soldCars.fold(0, (s, c) => s + c.purchase);

  double get totalExpenses =>
      cars.fold(0, (s, c) => s + c.expensesTotal);

  double get totalExpensesStock =>
      stockCars.fold(0, (s, c) => s + c.expensesTotal);

  double get totalExpensesSold =>
      soldCars.fold(0, (s, c) => s + c.expensesTotal);

  // === ИНВЕСТИЦИИ (закуп + расходы) ===
  double get totalInvested => totalPurchase + totalExpenses;
  double get totalInvestedStock =>
      totalPurchaseStock + totalExpensesStock;
  double get totalInvestedSold =>
      totalPurchaseSold + totalExpensesSold;

  // === ВЫРУЧКА И ПРИБЫЛЬ ===
  double get totalRevenue =>
      soldCars.fold(0, (s, c) => s + c.sale);

  double get totalProfit =>
      soldCars.fold(0, (s, c) => s + c.profit);

  // === СРЕДНИЕ ===
  double get averageProfit => soldCars.isEmpty
      ? 0
      : totalProfit / soldCars.length;

  double get averagePurchase =>
      cars.isEmpty ? 0 : totalPurchase / cars.length;

  double get averageSalePrice => soldCars.isEmpty
      ? 0
      : totalRevenue / soldCars.length;

  double get averageDaysToSell => soldCars.isEmpty
      ? 0
      : soldCars
              .map((c) => c.daysInStock)
              .reduce((a, b) => a + b) /
          soldCars.length;

  double get averageInvestment => cars.isEmpty
      ? 0
      : totalInvested / cars.length;

  // === РЕНТАБЕЛЬНОСТЬ ===
  double get profitability => totalInvestedSold == 0
      ? 0
      : (totalProfit / totalInvestedSold) * 100;

  // === ЛУЧШАЯ И ХУДШАЯ ===
  Car? get bestCar {
    if (soldCars.isEmpty) return null;
    return soldCars.reduce(
      (a, b) => a.profit >= b.profit ? a : b,
    );
  }

  Car? get worstCar {
    if (soldCars.isEmpty) return null;
    return soldCars.reduce(
      (a, b) => a.profit <= b.profit ? a : b,
    );
  }

  // === ТОП-5 РАСХОДОВ ПО КАТЕГОРИЯМ ===
  List<CategoryStat> get topExpenseCategories {
    final map = <String, double>{};
    for (final c in cars) {
      for (final e in c.expenses) {
        map[e.category] = (map[e.category] ?? 0) + e.amount;
      }
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(5)
        .map((e) => CategoryStat(name: e.key, amount: e.value))
        .toList();
  }

  // === ПРИБЫЛЬ ПО МЕСЯЦАМ (последние 6) ===
  List<MonthStat> get monthlyStats {
    final now = DateTime.now();
    final months = <MonthStat>[];
    for (int i = 5; i >= 0; i--) {
      final start = DateTime(now.year, now.month - i, 1);
      final end = DateTime(start.year, start.month + 1, 1);
      final soldInMonth = soldCars.where((c) {
        final d = c.saleDateTime;
        if (d == null) return false;
        return !d.isBefore(start) && d.isBefore(end);
      }).toList();
      final profit = soldInMonth.fold(0.0, (s, c) => s + c.profit);
      months.add(MonthStat(
        label: '${start.month.toString().padLeft(2, '0')}/'
            '${(start.year % 100).toString().padLeft(2, '0')}',
        profit: profit,
        count: soldInMonth.length,
      ));
    }
    return months;
  }

  // === ПРИБЫЛЬ ПО СТАТУСУ (сколько машин в каждом) ===
  Map<String, int> get statusCounts {
    final map = <String, int>{};
    for (final s in kStatuses) {
      map[s] = cars.where((c) => c.status == s).length;
    }
    return map;
  }
}
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;

  const _SectionTitle({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpensesTopCard extends StatelessWidget {
  final List<CategoryStat> stats;
  final double totalExpenses;

  const _ExpensesTopCard({
    required this.stats,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Расходов ещё нет'),
        ),
      );
    }
    const palette = [
      Colors.blue,
      Colors.deepOrange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < stats.length; i++) ...[
              Builder(builder: (context) {
                final s = stats[i];
                final pct = totalExpenses == 0
                    ? 0.0
                    : (s.amount / totalExpenses) * 100;
                final color = palette[i % palette.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            s.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${money(s.amount)}  •  '
                            '${pct.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (pct / 100).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor:
                              color.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final List<MonthStat> stats;

  const _MonthlyChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();
    final maxProfit = stats
        .map((m) => m.profit.abs())
        .fold<double>(0, (a, b) => a > b ? a : b);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: stats.map((m) {
                  final positive = m.profit >= 0;
                  final value = maxProfit == 0
                      ? 0.0
                      : (m.profit.abs() / maxProfit);
                  final barHeight = 10 + 90 * value;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            m.profit == 0
                                ? '—'
                                : moneyShort(m.profit),
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: positive
                                  ? Colors.green
                                  : Colors.red,
                              borderRadius:
                                  BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.label,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Прибыль по месяцам продаж (последние 6)',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _BestWorstCard extends StatelessWidget {
  final Car? best;
  final Car? worst;

  const _BestWorstCard({required this.best, required this.worst});

  @override
  Widget build(BuildContext context) {
    if (best == null && worst == null) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Лучшая',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (best != null) ...[
                    Text(
                      '${best!.make} ${best!.model}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      money(best!.profit),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else
                    const Text('—'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.trending_down,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Худшая',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (worst != null) ...[
                    Text(
                      '${worst!.make} ${worst!.model}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      money(worst!.profit),
                      style: TextStyle(
                        color: worst!.profit >= 0
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else
                    const Text('—'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
class _AnalyticsSection extends StatefulWidget {
  final Analytics analytics;

  const _AnalyticsSection({required this.analytics});

  @override
  State<_AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<_AnalyticsSection> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.analytics;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== KPI СЕТКА (всегда видна) =====
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.55,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            _KpiCard(
              title: 'Вложено всего',
              value: moneyShort(a.totalInvested),
              subtitle: 'закуп + расходы',
              icon: Icons.account_balance_wallet,
              color: Colors.blue,
            ),
            _KpiCard(
              title: 'Заработано',
              value: moneyShort(a.totalRevenue),
              subtitle: 'выручка от продаж',
              icon: Icons.savings,
              color: Colors.teal,
            ),
            _KpiCard(
              title: 'Чистая прибыль',
              value: moneyShort(a.totalProfit),
              subtitle: a.soldCars.isEmpty
                  ? 'нет проданных'
                  : '${a.soldCars.length} проданных',
              icon: Icons.trending_up,
              color: a.totalProfit >= 0
                  ? Colors.green
                  : Colors.red,
            ),
            _KpiCard(
              title: 'Средняя прибыль',
              value: moneyShort(a.averageProfit),
              subtitle: 'с одной машины',
              icon: Icons.attach_money,
              color: Colors.indigo,
            ),
            _KpiCard(
              title: 'В наличии',
              value: '${a.stockCars.length}',
              subtitle: moneyShort(a.totalInvestedStock),
              icon: Icons.directions_car,
              color: Colors.orange,
            ),
            _KpiCard(
              title: 'Проданных',
              value: '${a.soldCars.length}',
              subtitle: 'за всё время',
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            _KpiCard(
              title: 'Средний срок',
              value: a.soldCars.isEmpty
                  ? '—'
                  : '${a.averageDaysToSell.toStringAsFixed(0)} дн.',
              subtitle: 'от покупки до продажи',
              icon: Icons.schedule,
              color: Colors.deepPurple,
            ),
            _KpiCard(
              title: 'Рентабельность',
              value: a.soldCars.isEmpty
                  ? '—'
                  : '${a.profitability.toStringAsFixed(1)}%',
              subtitle: 'прибыль / вложено',
              icon: Icons.percent,
              color: Colors.pink,
            ),
          ],
        ),

        // ===== КНОПКА РАЗВЕРНУТЬ =====
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => setState(() => expanded = !expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Icon(
                    expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      expanded
                          ? 'Свернуть подробную аналитику'
                          : 'Развернуть подробную аналитику',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ===== ПОДРОБНАЯ АНАЛИТИКА =====
        if (expanded) ...[
          const SizedBox(height: 8),

          // --- Детализация ---
          const _SectionTitle(
            text: 'Детализация',
            icon: Icons.receipt_long,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Закупка всего',
                    value: money(a.totalPurchase),
                  ),
                  _DetailRow(
                    label: 'Расходы всего',
                    value: money(a.totalExpenses),
                  ),
                  const Divider(),
                  _DetailRow(
                    label: 'Итого вложено',
                    value: money(a.totalInvested),
                    valueColor: Colors.blue,
                  ),
                  const SizedBox(height: 6),
                  _DetailRow(
                    label: 'Вложено в наличие',
                    value: money(a.totalInvestedStock),
                    valueColor: Colors.orange,
                  ),
                  _DetailRow(
                    label: 'Вложено в проданные',
                    value: money(a.totalInvestedSold),
                  ),
                  const Divider(),
                  _DetailRow(
                    label: 'Выручка от продаж',
                    value: money(a.totalRevenue),
                    valueColor: Colors.teal,
                  ),
                  _DetailRow(
                    label: 'Чистая прибыль',
                    value: money(a.totalProfit),
                    valueColor: a.totalProfit >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ],
              ),
            ),
          ),

          // --- Средние показатели ---
          const _SectionTitle(
            text: 'Средние показатели',
            icon: Icons.analytics,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Средняя цена закупки',
                    value: money(a.averagePurchase),
                  ),
                  _DetailRow(
                    label: 'Средняя цена продажи',
                    value: money(a.averageSalePrice),
                  ),
                  _DetailRow(
                    label: 'Средняя прибыль',
                    value: money(a.averageProfit),
                    valueColor: a.averageProfit >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                  _DetailRow(
                    label: 'Средние вложения в машину',
                    value: money(a.averageInvestment),
                  ),
                  _DetailRow(
                    label: 'Средний срок продажи',
                    value: a.soldCars.isEmpty
                        ? '—'
                        : '${a.averageDaysToSell.toStringAsFixed(1)} дн.',
                  ),
                ],
              ),
            ),
          ),

          // --- Топ-5 расходов ---
          const _SectionTitle(
            text: 'Топ-5 расходов по категориям',
            icon: Icons.local_gas_station,
          ),
          _ExpensesTopCard(
            stats: a.topExpenseCategories,
            totalExpenses: a.totalExpenses,
          ),

          // --- Прибыль по месяцам ---
          const _SectionTitle(
            text: 'Прибыль по месяцам',
            icon: Icons.calendar_month,
          ),
          _MonthlyChart(stats: a.monthlyStats),

          // --- Лучшая / худшая ---
          const _SectionTitle(
            text: 'Лучшая и худшая машина',
            icon: Icons.emoji_events,
          ),
          _BestWorstCard(
            best: a.bestCar,
            worst: a.worstCar,
          ),

          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Car> cars = [];
  bool loading = true;
  final searchController = TextEditingController();
  String search = '';
  String listMode = 'stock'; // 'stock' | 'sold'

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await Storage.load();
    if (!mounted) return;
    setState(() {
      cars
        ..clear()
        ..addAll(data);
      loading = false;
    });
  }

  Future<void> _persist() async {
    await Storage.save(cars);
  }

  Analytics get analytics => Analytics(cars);

  List<Car> _filter(List<Car> src) {
    final q = search.trim().toLowerCase();
    if (q.isEmpty) return src;
    return src.where((c) {
      return c.make.toLowerCase().contains(q) ||
          c.model.toLowerCase().contains(q) ||
          c.vin.toLowerCase().contains(q) ||
          c.plate.toLowerCase().contains(q) ||
          c.seller.toLowerCase().contains(q);
    }).toList();
  }

  void addCar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarFormScreen(
          onSave: (car) {
            setState(() => cars.add(car));
            _persist();
          },
        ),
      ),
    );
  }

  void openCar(Car car) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarDetailsScreen(
          car: car,
          onChanged: () {
            if (!mounted) return;
            setState(() {});
            _persist();
          },
          onDelete: () async {
            for (final path in car.photos) {
              try {
                final f = File(path);
                if (await f.exists()) await f.delete();
              } catch (_) {}
            }
            if (!mounted) return;
            setState(() {
              cars.removeWhere((c) => c.id == car.id);
            });
            _persist();
          },
        ),
      ),
    );
  }

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      default:
        return Icons.brightness_auto;
    }
  }

  void _cycleTheme(ThemeMode mode) {
    final next = mode == ThemeMode.system
        ? ThemeMode.light
        : mode == ThemeMode.light
            ? ThemeMode.dark
            : ThemeMode.system;
    themeNotifier.value = next;
    Storage.saveTheme(next);
  }

  Future<void> exportJson() async {
    try {
      final data = jsonEncode(cars.map((c) => c.toJson()).toList());
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/auto_profit_backup.json');
      await file.writeAsString(data);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Резервная копия Авто Профит',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка экспорта: $e')),
      );
    }
  }

  Future<void> importJson() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null) return;
      final path = result.files.single.path;
      if (path == null) return;
      final content = await File(path).readAsString();
      final list = jsonDecode(content) as List;
      final imported = list
          .map((e) => Car.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() => cars.addAll(imported));
      _persist();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Импортировано ${imported.length} авто')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка импорта: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final a = analytics;
    final visible = _filter(
      listMode == 'stock' ? a.stockCars : a.soldCars,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Авто Профит'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') exportJson();
              if (value == 'csv') exportCsv(cars);
              if (value == 'import') importJson();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Экспорт JSON'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'csv',
                child: ListTile(
                  leading: Icon(Icons.table_chart),
                  title: Text('Экспорт CSV (Excel)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Импорт JSON'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, mode, _) => IconButton(
              tooltip: 'Тема',
              onPressed: () => _cycleTheme(mode),
              icon: Icon(_themeIcon(mode)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addCar,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: CustomScrollView(
        slivers: [
          // === АНАЛИТИКА ===
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                    text: 'Аналитика',
                    icon: Icons.insights,
                  ),
                  _AnalyticsSection(analytics: a),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // === ПОИСК ===
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: searchController,
                onChanged: (v) => setState(() => search = v),
                decoration: InputDecoration(
                  hintText: 'Поиск: марка, VIN, госномер…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: search.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            searchController.clear();
                            setState(() => search = '');
                          },
                        ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ),

          // === ФИЛЬТР-ПЕРЕКЛЮЧАТЕЛЬ ===
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: _ModeTab(
                      label: 'В наличии',
                      count: a.stockCars.length,
                      selected: listMode == 'stock',
                      onTap: () =>
                          setState(() => listMode = 'stock'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModeTab(
                      label: 'Проданные',
                      count: a.soldCars.length,
                      selected: listMode == 'sold',
                      onTap: () =>
                          setState(() => listMode = 'sold'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // === СКЛАД: ЗАГОЛОВОК ===
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Icon(
                    listMode == 'stock'
                        ? Icons.warehouse
                        : Icons.inventory,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    listMode == 'stock'
                        ? 'Автомобили в наличии'
                        : 'Проданные автомобили',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // === СПИСОК МАШИН ===
          if (visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        listMode == 'stock'
                            ? Icons.directions_car_outlined
                            : Icons.check_circle_outline,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        search.isNotEmpty
                            ? 'Ничего не найдено'
                            : listMode == 'stock'
                                ? 'Нет машин в наличии'
                                : 'Нет проданных машин',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
              sliver: SliverList.builder(
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final car = visible[index];
                  return _CarListTile(
                    car: car,
                    onTap: () => openCar(car),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: selected ? 2 : 0,
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              '$label ($count)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class _CarListTile extends StatelessWidget {
  final Car car;
  final VoidCallback onTap;

  const _CarListTile({required this.car, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photos = car.photos;
    final days = car.daysInStock;

    // Цвет статуса по свежести
    Color daysColor = Colors.green;
    if (car.isSold) {
      daysColor = Colors.blueGrey;
    } else if (days >= 60) {
      daysColor = Colors.red;
    } else if (days >= 30) {
      daysColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PhotoThumb(path: photos.isNotEmpty ? photos.first : null),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${car.make} ${car.model}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (car.year.isNotEmpty) car.year,
                        if (car.plate.isNotEmpty) car.plate,
                        car.status,
                      ].join(' • '),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    if (car.isSold)
                      Text(
                        'Прибыль: ${money(car.profit)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: car.profit >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      )
                    else ...[
                      Text(
                        'Вложено: ${money(car.invested)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 14, color: daysColor),
                          const SizedBox(width: 4),
                          Text(
                            'На складе $days дн.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: daysColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final String? path;

  const _PhotoThumb({required this.path});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 72.0;
    if (path == null || path!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.directions_car,
          size: 36,
          color: theme.colorScheme.primary,
        ),
      );
    }
    final file = File(path!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: file.existsSync()
            ? Image.file(file, fit: BoxFit.cover)
            : Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image),
              ),
      ),
    );
  }
}
class CarFormScreen extends StatefulWidget {
  final Car? car;
  final void Function(Car car) onSave;

  const CarFormScreen({
    super.key,
    this.car,
    required this.onSave,
  });

  @override
  State<CarFormScreen> createState() => _CarFormScreenState();
}

class _CarFormScreenState extends State<CarFormScreen> {
  final make = TextEditingController();
  final model = TextEditingController();
  final year = TextEditingController();
  final vin = TextEditingController();
  final plate = TextEditingController();
  final mileage = TextEditingController();
  final purchase = TextEditingController();
  final seller = TextEditingController();
  final sellerPhone = TextEditingController();
  final sellerAddress = TextEditingController();
  final notes = TextEditingController();

  String status = 'Куплен';
  DateTime? purchaseDate;

  bool get isEdit => widget.car != null;

  @override
  void initState() {
    super.initState();
    final c = widget.car;
    if (c != null) {
      make.text = c.make;
      model.text = c.model;
      year.text = c.year;
      vin.text = c.vin;
      plate.text = c.plate;
      mileage.text = c.mileage;
      purchase.text = c.purchasePrice;
      seller.text = c.seller;
      sellerPhone.text = c.sellerPhone;
      sellerAddress.text = c.sellerAddress;
      notes.text = c.notes;
      status = c.status;
      purchaseDate = c.purchaseDateTime;
    } else {
      purchaseDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    make.dispose();
    model.dispose();
    year.dispose();
    vin.dispose();
    plate.dispose();
    mileage.dispose();
    purchase.dispose();
    seller.dispose();
    sellerPhone.dispose();
    sellerAddress.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> pickPurchaseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: purchaseDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => purchaseDate = picked);
    }
  }

  void save() {
    if (make.text.trim().isEmpty ||
        model.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите марку и модель')),
      );
      return;
    }
    final iso = purchaseDate == null
        ? ''
        : '${purchaseDate!.year.toString().padLeft(4, '0')}-'
            '${purchaseDate!.month.toString().padLeft(2, '0')}-'
            '${purchaseDate!.day.toString().padLeft(2, '0')}';

    if (isEdit) {
      final c = widget.car!;
      c.make = make.text.trim();
      c.model = model.text.trim();
      c.year = year.text.trim();
      c.vin = vin.text.trim();
      c.plate = plate.text.trim();
      c.mileage = mileage.text.trim();
      c.purchasePrice = purchase.text.trim();
      c.purchaseDate = iso;
      c.status = status;
      c.seller = seller.text.trim();
      c.sellerPhone = sellerPhone.text.trim();
      c.sellerAddress = sellerAddress.text.trim();
      c.notes = notes.text.trim();
      widget.onSave(c);
    } else {
      widget.onSave(
        Car(
          id: newId(),
          make: make.text.trim(),
          model: model.text.trim(),
          year: year.text.trim(),
          vin: vin.text.trim(),
          plate: plate.text.trim(),
          mileage: mileage.text.trim(),
          purchasePrice: purchase.text.trim(),
          purchaseDate: iso,
          status: status,
          seller: seller.text.trim(),
          sellerPhone: sellerPhone.text.trim(),
          sellerAddress: sellerAddress.text.trim(),
          notes: notes.text.trim(),
          salePrice: '',
          saleDate: '',
          expenses: [],
          photos: [],
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Редактировать авто' : 'Новый автомобиль',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          field(make, 'Марка'),
          field(model, 'Модель'),
          field(year, 'Год'),
          field(vin, 'VIN'),
          field(plate, 'Госномер'),
          field(mileage, 'Пробег'),
          field(purchase, 'Цена покупки', number: true),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: pickPurchaseDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Дата покупки',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  purchaseDate == null
                      ? 'Не указана'
                      : formatDate(purchaseDate!),
                ),
              ),
            ),
          ),
          field(seller, 'Продавец (имя)'),
          field(sellerPhone, 'Телефон продавца', number: true),
          field(sellerAddress, 'Адрес / город'),
          field(notes, 'Примечания', lines: 4),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(
              labelText: 'Статус',
              border: OutlineInputBorder(),
            ),
            items: kStatuses
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => status = value);
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: save,
            icon: const Icon(Icons.save),
            label: Text(
              isEdit ? 'Сохранить изменения' : 'Сохранить автомобиль',
            ),
          ),
        ],
      ),
    );
  }

  Widget field(
    TextEditingController controller,
    String label, {
    bool number = false,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: lines,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
class CarDetailsScreen extends StatefulWidget {
  final Car car;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const CarDetailsScreen({
    super.key,
    required this.car,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  final salePrice = TextEditingController();
  DateTime? saleDate;

  @override
  void initState() {
    super.initState();
    salePrice.text = widget.car.salePrice;
    saleDate = widget.car.saleDateTime;
  }

  @override
  void dispose() {
    salePrice.dispose();
    super.dispose();
  }

  Future<void> _call() async {
    final phone =
        widget.car.sellerPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openAddress() async {
    final addr = widget.car.sellerAddress;
    if (addr.isEmpty) return;
    final uri = Uri.parse(
      'https://yandex.ru/maps/?text=${Uri.encodeComponent(addr)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> addPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Из галереи'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Сделать фото'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1600,
    );
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'photos'));
    if (!await photosDir.exists()) await photosDir.create(recursive: true);
    final newPath = p.join(
      photosDir.path,
      'photo_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await File(picked.path).copy(newPath);
    setState(() {
      widget.car.photos.add(newPath);
    });
    widget.onChanged();
  }

  Future<void> removePhoto(int index) async {
    final path = widget.car.photos[index];
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    setState(() {
      widget.car.photos.removeAt(index);
    });
    widget.onChanged();
  }

  void saveSale() {
    setState(() {
      widget.car.salePrice = salePrice.text.trim();
      widget.car.saleDate = saleDate == null
          ? todayIso()
          : '${saleDate!.year.toString().padLeft(4, '0')}-'
              '${saleDate!.month.toString().padLeft(2, '0')}-'
              '${saleDate!.day.toString().padLeft(2, '0')}';
      if (widget.car.sale > 0) widget.car.status = 'Продан';
    });
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сохранено')),
    );
  }

  Future<void> pickSaleDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: saleDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => saleDate = picked);
  }

  void editCar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarFormScreen(
          car: widget.car,
          onSave: (_) {
            setState(() {});
            widget.onChanged();
          },
        ),
      ),
    );
  }

  void confirmDeleteCar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить автомобиль?'),
        content: const Text(
          'Автомобиль, его расходы и фотографии будут удалены. Действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete();
              Navigator.pop(context);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;

    return Scaffold(
      appBar: AppBar(
        title: Text('${car.make} ${car.model}'),
        actions: [
          IconButton(
            tooltip: 'Редактировать',
            onPressed: editCar,
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            tooltip: 'Удалить',
            onPressed: confirmDeleteCar,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PhotosBlock(
            car: car,
            onAdd: addPhoto,
            onRemove: removePhoto,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${car.make} ${car.model}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _infoRow('Год', car.year),
                  _infoRow('VIN', car.vin),
                  _infoRow('Госномер', car.plate),
                  _infoRow('Пробег', car.mileage),
                  _infoRow('Статус', car.status),
                  _infoRow(
                    'Дата покупки',
                    car.purchaseDate.isEmpty
                        ? ''
                        : formatDate(car.purchaseDateTime!),
                  ),
                  _infoRow('На складе', '${car.daysInStock} дн.'),
                  if (car.saleDate.isNotEmpty)
                    _infoRow(
                      'Дата продажи',
                      formatDate(car.saleDateTime!),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (car.seller.isNotEmpty ||
              car.sellerPhone.isNotEmpty ||
              car.sellerAddress.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Продавец',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (car.seller.isNotEmpty) Text(car.seller),
                    if (car.sellerPhone.isNotEmpty)
                      Text('Тел: ${car.sellerPhone}'),
                    if (car.sellerAddress.isNotEmpty)
                      Text('Адрес: ${car.sellerAddress}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (car.sellerPhone.isNotEmpty)
                          FilledButton.icon(
                            onPressed: _call,
                            icon: const Icon(Icons.phone),
                            label: const Text('Позвонить'),
                          ),
                        if (car.sellerAddress.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: _openAddress,
                            icon: const Icon(Icons.map),
                            label: const Text('Карта'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Финансы',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  financeRow('Цена покупки', car.purchase),
                  financeRow('Расходы', car.expensesTotal),
                  const Divider(),
                  financeRow('Всего вложено', car.invested, bold: true),
                  financeRow('Цена продажи', car.sale),
                  financeRow('Прибыль', car.profit, bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ExpensesBlock(car: car, onChanged: widget.onChanged),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Продажа',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: salePrice,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Цена продажи',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: pickSaleDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Дата продажи',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        saleDate == null
                            ? 'Не указана'
                            : formatDate(saleDate!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: saveSale,
                    child: const Text('Сохранить продажу'),
                  ),
                ],
              ),
            ),
          ),
          if (car.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Примечания',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(car.notes),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('$title: $value'),
    );
  }

  Widget financeRow(
    String title,
    double value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
          ),
          Text(
            money(value),
            style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
          ),
        ],
      ),
    );
  }
}
class _PhotosBlock extends StatelessWidget {
  final Car car;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const _PhotosBlock({
    required this.car,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Фотографии',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_a_photo),
                ),
              ],
            ),
            if (car.photos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Фото пока нет'),
              )
            else
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: car.photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final file = File(car.photos[index]);
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 110,
                            height: 110,
                            child: file.existsSync()
                                ? Image.file(file, fit: BoxFit.cover)
                                : Container(
                                    color: Colors.black12,
                                    child: const Icon(Icons.broken_image),
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => onRemove(index),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpensesBlock extends StatelessWidget {
  final Car car;
  final VoidCallback onChanged;

  const _ExpensesBlock({required this.car, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Расходы',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => showExpenseDialog(
                    context: context,
                    car: car,
                    onChanged: onChanged,
                  ),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            if (car.expenses.isEmpty)
              const Text('Расходов пока нет')
            else
              ...car.expenses.map(
                (expense) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.receipt_long),
                  title: Text(expense.category),
                  subtitle: Text(
                    expense.note.isEmpty
                        ? 'Нажмите, чтобы изменить'
                        : expense.note,
                  ),
                  trailing: Text(
                    money(expense.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => showExpenseDialog(
                    context: context,
                    car: car,
                    expense: expense,
                    onChanged: onChanged,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> showExpenseDialog({
  required BuildContext context,
  required Car car,
  Expense? expense,
  required VoidCallback onChanged,
}) async {
  final amount = TextEditingController(
    text: expense != null ? expense.amount.toStringAsFixed(0) : '',
  );
  final note = TextEditingController(text: expense?.note ?? '');
  String category = expense?.category ?? kExpenseCategories.first;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: Text(
              expense == null ? 'Добавить расход' : 'Изменить расход',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(
                      labelText: 'Категория',
                      border: OutlineInputBorder(),
                    ),
                    items: kExpenseCategories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setLocal(() => category = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Сумма',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: note,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Комментарий',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (expense != null)
                TextButton(
                  onPressed: () {
                    car.expenses.removeWhere((e) => e.id == expense.id);
                    onChanged();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Удалить',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () {
                  final value = double.tryParse(
                        amount.text.replaceAll(',', '.'),
                      ) ??
                      0;
                  if (value <= 0) return;
                  if (expense == null) {
                    car.expenses.add(
                      Expense(
                        id: newId(),
                        category: category,
                        amount: value,
                        note: note.text.trim(),
                      ),
                    );
                  } else {
                    expense.category = category;
                    expense.amount = value;
                    expense.note = note.text.trim();
                  }
                  onChanged();
                  Navigator.pop(dialogContext);
                },
                child: Text(expense == null ? 'Добавить' : 'Сохранить'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> exportCsv(List<Car> cars) async {
  final buf = StringBuffer();
  buf.writeln(
    'Марка;Модель;Год;VIN;Госномер;Статус;Дата покупки;Дней на складе;'
    'Цена покупки;Расходы;Всего вложено;Цена продажи;Дата продажи;Прибыль',
  );
  for (final c in cars) {
    buf.writeln([
      c.make,
      c.model,
      c.year,
      c.vin,
      c.plate,
      c.status,
      c.purchaseDate,
      c.daysInStock,
      c.purchase.toStringAsFixed(0),
      c.expensesTotal.toStringAsFixed(0),
      c.invested.toStringAsFixed(0),
      c.sale.toStringAsFixed(0),
      c.saleDate,
      c.profit.toStringAsFixed(0),
    ].join(';'));
  }
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/auto_profit_report.csv');
  await file.writeAsString(buf.toString());
  await Share.shareXFiles(
    [XFile(file.path)],
    text: 'Отчёт Авто Профит',
  );
}
