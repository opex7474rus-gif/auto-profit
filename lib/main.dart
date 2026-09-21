import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
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

const int kStaleDays = 30;
const int kReminderDays = 3;
const String kLastCheckKey = 'last_check_v1';
const int kTrashDays = 30;

const Map<String, List<String>> kCarCatalog = {
  'Lada': ['Granta', 'Vesta', 'Largus', 'Niva', 'XRAY', 'Kalina', 'Priora', '2107', '2110', '2114', '2115'],
  'Toyota': ['Camry', 'Corolla', 'RAV4', 'Land Cruiser', 'Highlander', 'Prius', 'Avensis'],
  'Kia': ['Rio', 'Sportage', 'Optima', 'Ceed', 'Sorento', 'Soul', 'Cerato'],
  'Hyundai': ['Solaris', 'Creta', 'Tucson', 'Santa Fe', 'Elantra', 'i30', 'ix35', 'Accent'],
  'Volkswagen': ['Polo', 'Tiguan', 'Passat', 'Golf', 'Jetta', 'Touareg'],
  'Renault': ['Logan', 'Duster', 'Sandero', 'Kaptur', 'Arkana', 'Megane'],
  'Nissan': ['Qashqai', 'X-Trail', 'Juke', 'Almera', 'Teana', 'Murano', 'Note'],
  'Ford': ['Focus', 'Mondeo', 'Kuga', 'Explorer', 'Fiesta', 'Transit'],
  'Skoda': ['Octavia', 'Rapid', 'Superb', 'Kodiaq', 'Karoq', 'Fabia', 'Yeti'],
  'BMW': ['3 серия', '5 серия', '7 серия', 'X1', 'X3', 'X5', 'X6'],
  'Mercedes-Benz': ['C-класс', 'E-класс', 'S-класс', 'GLA', 'GLC', 'GLE', 'ML', 'Sprinter'],
  'Audi': ['A3', 'A4', 'A6', 'A8', 'Q3', 'Q5', 'Q7'],
  'Mazda': ['3', '6', 'CX-5', 'CX-9', 'CX-30'],
  'Chevrolet': ['Cruze', 'Aveo', 'Lacetti', 'Niva', 'Captiva', 'Malibu', 'Spark'],
  'Mitsubishi': ['Lancer', 'Outlander', 'ASX', 'Pajero', 'L200', 'Galant'],
  'Opel': ['Astra', 'Corsa', 'Insignia', 'Zafira', 'Mokka', 'Antara'],
  'Peugeot': ['308', '408', '3008', '4008', '5008', 'Partner'],
  'Citroen': ['C4', 'C5', 'Berlingo', 'C3', 'C-Elysee'],
  'Honda': ['Civic', 'Accord', 'CR-V', 'Pilot', 'Fit', 'Jazz'],
  'Suzuki': ['Vitara', 'SX4', 'Jimny', 'Grand Vitara', 'Swift'],
  'Chery': ['Tiggo 4', 'Tiggo 7', 'Tiggo 8', 'Arrizo 5', 'Arrizo 8'],
  'Haval': ['H6', 'H9', 'Jolion', 'F7', 'Dargo', 'H5'],
  'Geely': ['Coolray', 'Atlas', 'Tugella', 'Monjaro', 'Emgrand'],
  'Datsun': ['on-DO', 'mi-DO'],
  'Daewoo': ['Nexia', 'Matiz', 'Gentra'],
  'Ravon': ['Nexia R3', 'R2', 'R4'],
  'УАЗ': ['Patriot', 'Hunter', 'Profi', '452'],
  'ГАЗ': ['Газель', 'Соболь', 'Волга'],
};

const Map<String, String> kDefaultBuyerData = {
  'fio': '',
  'passport': '',
  'address': '',
  'phone': '',
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  themeNotifier.value = await Storage.loadTheme();
  await Storage.cleanupTrash();
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
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
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
class Attachment {
  String id;
  String name;
  String path;
  String type;
  String addedAt;

  Attachment({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.addedAt,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        id: (json['id'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        path: (json['path'] ?? '') as String,
        type: (json['type'] ?? 'other') as String,
        addedAt: (json['addedAt'] ?? '') as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'type': type,
        'addedAt': addedAt,
      };
}

class TrashEntry {
  Car car;
  String deletedAt;

  TrashEntry({required this.car, required this.deletedAt});

  factory TrashEntry.fromJson(Map<String, dynamic> json) => TrashEntry(
        car: Car.fromJson(json['car'] as Map<String, dynamic>),
        deletedAt: (json['deletedAt'] ?? '') as String,
      );

  Map<String, dynamic> toJson() => {
        'car': car.toJson(),
        'deletedAt': deletedAt,
      };

  int get daysLeft {
    final d = DateTime.tryParse(deletedAt);
    if (d == null) return 0;
    final diff = kTrashDays - DateTime.now().difference(d).inDays;
    return diff < 0 ? 0 : diff;
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
  String statusChangedAt;
  String seller;
  String sellerPhone;
  String sellerAddress;
  String notes;
  String salePrice;
  String saleDate;
  List<Expense> expenses;
  List<String> photos;
  List<Attachment> attachments;

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
    required this.statusChangedAt,
    required this.seller,
    required this.sellerPhone,
    required this.sellerAddress,
    required this.notes,
    required this.salePrice,
    required this.saleDate,
    required this.expenses,
    required this.photos,
    required this.attachments,
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
      statusChangedAt: (json['statusChangedAt'] ?? '') as String,
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
      attachments: ((json['attachments'] ?? []) as List)
          .map((e) => Attachment.fromJson(e as Map<String, dynamic>))
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
        'statusChangedAt': statusChangedAt,
        'seller': seller,
        'sellerPhone': sellerPhone,
        'sellerAddress': sellerAddress,
        'notes': notes,
        'salePrice': salePrice,
        'saleDate': saleDate,
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'photos': photos,
        'attachments': attachments.map((a) => a.toJson()).toList(),
      };

  Car duplicate() => Car(
        id: newId(),
        make: make,
        model: model,
        year: year,
        vin: '',
        plate: '',
        mileage: mileage,
        purchasePrice: purchasePrice,
        purchaseDate: todayIso(),
        status: 'Куплен',
        statusChangedAt: todayIso(),
        seller: seller,
        sellerPhone: sellerPhone,
        sellerAddress: sellerAddress,
        notes: notes,
        salePrice: '',
        saleDate: '',
        expenses: [],
        photos: [],
        attachments: [],
      );

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

  DateTime? get statusChangedDateTime {
    if (statusChangedAt.isEmpty) return null;
    return DateTime.tryParse(statusChangedAt);
  }

  int get daysInStock {
    final start = purchaseDateTime;
    if (start == null) return 0;
    final end = saleDateTime ?? DateTime.now();
    return end.difference(start).inDays;
  }

  int get daysInCurrentStatus {
    final d = statusChangedDateTime;
    if (d == null) return daysInStock;
    return DateTime.now().difference(d).inDays;
  }

  bool get isStale =>
      !isSold &&
      statusChangedAt.isNotEmpty &&
      daysInCurrentStatus >= kStaleDays;
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

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: (json['id'] ?? '') as String,
        category: (json['category'] ?? 'Прочее') as String,
        amount: ((json['amount'] ?? 0) as num).toDouble(),
        note: (json['note'] ?? '') as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'amount': amount,
        'note': note,
      };
}
class Storage {
  static const _key = 'cars_v1';
  static const _trashKey = 'cars_trash_v1';
  static const _themeKey = 'theme_mode_v1';
  static const _sellerKey = 'seller_data_v1';
  static const _buyerKey = 'buyer_data_v1';

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

  static Future<List<TrashEntry>> loadTrash() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_trashKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => TrashEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTrash(List<TrashEntry> trash) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _trashKey,
      jsonEncode(trash.map((t) => t.toJson()).toList()),
    );
  }

  static Future<void> cleanupTrash() async {
    final trash = await loadTrash();
    final now = DateTime.now();
    final cleaned = <TrashEntry>[];
    for (final t in trash) {
      final d = DateTime.tryParse(t.deletedAt);
      if (d == null) continue;
      if (now.difference(d).inDays < kTrashDays) {
        cleaned.add(t);
      } else {
        // удаляем файлы
        for (final path in t.car.photos) {
          try {
            final f = File(path);
            if (await f.exists()) await f.delete();
          } catch (_) {}
        }
        for (final a in t.car.attachments) {
          try {
            final f = File(a.path);
            if (await f.exists()) await f.delete();
          } catch (_) {}
        }
      }
    }
    await saveTrash(cleaned);
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

  static Future<Map<String, String>> loadPartyData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return Map.from(kDefaultBuyerData);
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return Map.from(kDefaultBuyerData);
    }
  }

  static Future<void> savePartyData(
    String key,
    Map<String, String> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }

  static Future<Map<String, String>> loadSellerData() =>
      loadPartyData(_sellerKey);

  static Future<void> saveSellerData(Map<String, String> data) =>
      savePartyData(_sellerKey, data);

  static Future<Map<String, String>> loadBuyerData() =>
      loadPartyData(_buyerKey);

  static Future<void> saveBuyerData(Map<String, String> data) =>
      savePartyData(_buyerKey, data);
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

String dateToIso(DateTime d) {
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

List<String> get kYearList {
  final now = DateTime.now().year;
  final years = <String>[];
  for (int y = now + 1; y >= 1990; y--) {
    years.add(y.toString());
  }
  return years;
}

bool isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;
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
  List<Car> get staleCars => cars.where((c) => c.isStale).toList();

  List<Car> get soldThisMonth => soldCars.where((c) {
        final d = c.saleDateTime;
        if (d == null) return false;
        return isSameMonth(d, DateTime.now());
      }).toList();

  int get soldThisMonthCount => soldThisMonth.length;
  int get soldAllTimeCount => soldCars.length;

  double get profitThisMonth =>
      soldThisMonth.fold(0.0, (s, c) => s + c.profit);

  double get totalPurchase => cars.fold(0, (s, c) => s + c.purchase);
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

  double get totalInvested => totalPurchase + totalExpenses;
  double get totalInvestedStock =>
      totalPurchaseStock + totalExpensesStock;
  double get totalInvestedSold =>
      totalPurchaseSold + totalExpensesSold;

  double get totalRevenue =>
      soldCars.fold(0, (s, c) => s + c.sale);

  double get totalProfit =>
      soldCars.fold(0, (s, c) => s + c.profit);

  double get averageProfit =>
      soldCars.isEmpty ? 0 : totalProfit / soldCars.length;

  double get averagePurchase =>
      cars.isEmpty ? 0 : totalPurchase / cars.length;

  double get averageSalePrice =>
      soldCars.isEmpty ? 0 : totalRevenue / soldCars.length;

  double get averageDaysToSell => soldCars.isEmpty
      ? 0
      : soldCars.map((c) => c.daysInStock).reduce((a, b) => a + b) /
          soldCars.length;

  double get averageInvestment =>
      cars.isEmpty ? 0 : totalInvested / cars.length;

  double get profitability => totalInvestedSold == 0
      ? 0
      : (totalProfit / totalInvestedSold) * 100;

  Car? get bestCar {
    if (soldCars.isEmpty) return null;
    return soldCars.reduce((a, b) => a.profit >= b.profit ? a : b);
  }

  Car? get worstCar {
    if (soldCars.isEmpty) return null;
    return soldCars.reduce((a, b) => a.profit <= b.profit ? a : b);
  }

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
                maxLines: 2,
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
            for (int i = 0; i < stats.length; i++)
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
                            m.profit == 0 ? '—' : moneyShort(m.profit),
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              color:
                                  positive ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(4),
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
    if (best == null && worst == null) return const SizedBox.shrink();
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
                      const Icon(Icons.emoji_events,
                          color: Colors.green, size: 18),
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
                      const Icon(Icons.trending_down,
                          color: Colors.red, size: 18),
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
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
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
              color: a.totalProfit >= 0 ? Colors.green : Colors.red,
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
              value: '${a.soldThisMonthCount} в этом месяце',
              subtitle: '${a.soldAllTimeCount} за всё время',
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
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      expanded
                          ? 'Свернуть подробную аналитику'
                          : 'Развернуть подробную аналитику',
                      style:
                          const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 8),
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
                    label: 'Прибыль за этот месяц',
                    value: money(a.profitThisMonth),
                    valueColor: a.profitThisMonth >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                  _DetailRow(
                    label: 'Прибыль за всё время',
                    value: money(a.totalProfit),
                    valueColor:
                        a.totalProfit >= 0 ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
          ),
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
          const _SectionTitle(
            text: 'Топ-5 расходов по категориям',
            icon: Icons.local_gas_station,
          ),
          _ExpensesTopCard(
            stats: a.topExpenseCategories,
            totalExpenses: a.totalExpenses,
          ),
          const _SectionTitle(
            text: 'Прибыль по месяцам',
            icon: Icons.calendar_month,
          ),
          _MonthlyChart(stats: a.monthlyStats),
          const _SectionTitle(
            text: 'Лучшая и худшая машина',
            icon: Icons.emoji_events,
          ),
          _BestWorstCard(best: a.bestCar, worst: a.worstCar),
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
  String listMode = 'stock';
  String sortMode = 'purchaseDesc';
  bool showCheckReminder = false;
  int trashCount = 0;

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
    final trash = await Storage.loadTrash();
    if (!mounted) return;
    setState(() {
      cars
        ..clear()
        ..addAll(data);
      trashCount = trash.length;
      loading = false;
    });
    _checkReminder();
  }

  Future<void> _checkReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString(kLastCheckKey);
    if (lastStr == null) {
      await prefs.setString(kLastCheckKey, todayIso());
      return;
    }
    final last = DateTime.tryParse(lastStr);
    if (last == null) return;
    final diff = DateTime.now().difference(last).inDays;
    if (!mounted) return;
    setState(() => showCheckReminder = diff >= kReminderDays);
  }

  Future<void> _dismissReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kLastCheckKey, todayIso());
    setState(() => showCheckReminder = false);
  }

  Future<void> _persist() async => Storage.save(cars);

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

  List<Car> _sort(List<Car> src) {
    final list = List<Car>.from(src);
    switch (sortMode) {
      case 'purchaseAsc':
        list.sort((a, b) {
          final da = a.purchaseDateTime ?? DateTime(2100);
          final db = b.purchaseDateTime ?? DateTime(2100);
          return da.compareTo(db);
        });
        break;
      case 'profitDesc':
        list.sort((a, b) => b.profit.compareTo(a.profit));
        break;
      case 'alpha':
        list.sort((a, b) => '${a.make} ${a.model}'
            .toLowerCase()
            .compareTo('${b.make} ${b.model}'.toLowerCase()));
        break;
      case 'daysDesc':
        list.sort((a, b) => b.daysInStock.compareTo(a.daysInStock));
        break;
      case 'purchaseDesc':
      default:
        list.sort((a, b) {
          final da = a.purchaseDateTime ?? DateTime(1900);
          final db = b.purchaseDateTime ?? DateTime(1900);
          return db.compareTo(da);
        });
    }
    return list;
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
            final trash = await Storage.loadTrash();
            trash.add(
              TrashEntry(car: car, deletedAt: todayIso()),
            );
            await Storage.saveTrash(trash);
            if (!mounted) return;
            setState(() {
              cars.removeWhere((c) => c.id == car.id);
              trashCount = trash.length;
            });
            _persist();
          },
          onDuplicate: (newCar) {
            setState(() => cars.add(newCar));
            _persist();
          },
        ),
      ),
    );
  }

  void openTrash() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrashScreen(
          onRestore: (car) {
            setState(() => cars.add(car));
            _persist();
            _load();
          },
        ),
      ),
    );
    _load();
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
    final sourceList = listMode == 'stock' ? a.stockCars : a.soldCars;
    final visible = _sort(_filter(sourceList));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Авто Профит'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') exportJson();
              if (value == 'csv') exportCsv(cars);
              if (value == 'import') importJson();
              if (value == 'trash') openTrash();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Экспорт JSON'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'csv',
                child: ListTile(
                  leading: Icon(Icons.table_chart),
                  title: Text('Экспорт CSV (Excel)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Импорт JSON'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'trash',
                child: ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text('Корзина ($trashCount)'),
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
          if (showCheckReminder)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active,
                        color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Прошло $kReminderDays дня. Проверьте машины на складе.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: _dismissReminder,
                      child: const Text('Ок'),
                    ),
                  ],
                ),
              ),
            ),
          if (a.staleCars.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${a.staleCars.length} машин(ы) '
                        'без изменения статуса больше $kStaleDays дней',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                      onTap: () => setState(() => listMode = 'stock'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModeTab(
                      label: 'Проданные',
                      count: a.soldCars.length,
                      selected: listMode == 'sold',
                      onTap: () => setState(() => listMode = 'sold'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
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
                  Expanded(
                    child: Text(
                      listMode == 'stock' ? 'В наличии' : 'Проданные',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.sort),
                    tooltip: 'Сортировка',
                    onSelected: (v) => setState(() => sortMode = v),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'purchaseDesc',
                        child: Text('По дате покупки ↓'),
                      ),
                      PopupMenuItem(
                        value: 'purchaseAsc',
                        child: Text('По дате покупки ↑'),
                      ),
                      PopupMenuItem(
                        value: 'profitDesc',
                        child: Text('По прибыли'),
                      ),
                      PopupMenuItem(
                        value: 'daysDesc',
                        child: Text('По дням на складе'),
                      ),
                      PopupMenuItem(
                        value: 'alpha',
                        child: Text('По алфавиту'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
              _PhotoThumb(
                path: photos.isNotEmpty ? photos.first : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${car.make} ${car.model}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (car.isStale)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Залежалась',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                              ),
                            ),
                          ),
                      ],
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
                        style:
                            const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 14, color: daysColor),
                          const SizedBox(width: 4),
                          Text(
                            'На складе $days дн.',
                            style:
                                theme.textTheme.bodySmall?.copyWith(
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
class _AutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final Iterable<String> Function(String) optionsBuilder;
  final VoidCallback? onChangedCallback;

  const _AutocompleteField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.optionsBuilder,
    this.onChangedCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RawAutocomplete<String>(
        textEditingController: controller,
        focusNode: focusNode,
        optionsBuilder: (tv) {
          final q = tv.text.trim();
          if (q.isEmpty) return const Iterable<String>.empty();
          return optionsBuilder(q);
        },
        onSelected: (value) {
          controller.text = value;
          onChangedCallback?.call();
        },
        fieldViewBuilder: (context, c, fn, onSubmitted) {
          return TextField(
            controller: c,
            focusNode: fn,
            onChanged: (_) => onChangedCallback?.call(),
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  c.clear();
                  onChangedCallback?.call();
                },
              ),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220, maxWidth: 320),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Text(option),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
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

  final makeFocus = FocusNode();
  final modelFocus = FocusNode();
  final yearFocus = FocusNode();
  final vinFocus = FocusNode();
  final plateFocus = FocusNode();
  final mileageFocus = FocusNode();
  final purchaseFocus = FocusNode();
  final sellerFocus = FocusNode();
  final sellerPhoneFocus = FocusNode();
  final sellerAddressFocus = FocusNode();
  final notesFocus = FocusNode();

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
    makeFocus.dispose();
    modelFocus.dispose();
    yearFocus.dispose();
    vinFocus.dispose();
    plateFocus.dispose();
    mileageFocus.dispose();
    purchaseFocus.dispose();
    sellerFocus.dispose();
    sellerPhoneFocus.dispose();
    sellerAddressFocus.dispose();
    notesFocus.dispose();
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
    if (picked != null) setState(() => purchaseDate = picked);
  }

  void save() {
    if (make.text.trim().isEmpty || model.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите марку и модель')),
      );
      return;
    }
    final iso = purchaseDate == null ? '' : dateToIso(purchaseDate!);

    if (isEdit) {
      final c = widget.car!;
      if (c.status != status) c.statusChangedAt = todayIso();
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
          statusChangedAt: todayIso(),
          seller: seller.text.trim(),
          sellerPhone: sellerPhone.text.trim(),
          sellerAddress: sellerAddress.text.trim(),
          notes: notes.text.trim(),
          salePrice: '',
          saleDate: '',
          expenses: [],
          photos: [],
          attachments: [],
        ),
      );
    }
    Navigator.pop(context);
  }

  Widget field(
    TextEditingController controller,
    FocusNode focusNode,
    String label, {
    bool number = false,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
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
          _AutocompleteField(
            controller: make,
            focusNode: makeFocus,
            label: 'Марка',
            optionsBuilder: (q) {
              final lower = q.toLowerCase();
              return kCarCatalog.keys
                  .where((m) => m.toLowerCase().contains(lower));
            },
            onChangedCallback: () => setState(() {}),
          ),
          _AutocompleteField(
            controller: model,
            focusNode: modelFocus,
            label: 'Модель',
            optionsBuilder: (q) {
              final brand = make.text.trim();
              final lower = q.toLowerCase();
              if (brand.isEmpty) {
                final all = kCarCatalog.values
                    .expand((e) => e)
                    .toSet()
                    .toList();
                return all.where((m) => m.toLowerCase().contains(lower));
              }
              final models = kCarCatalog[brand] ?? [];
              return models.where(
                (m) => m.toLowerCase().contains(lower),
              );
            },
          ),
          _AutocompleteField(
            controller: year,
            focusNode: yearFocus,
            label: 'Год',
            optionsBuilder: (q) =>
                kYearList.where((y) => y.startsWith(q)),
          ),
          field(vin, vinFocus, 'VIN'),
          field(plate, plateFocus, 'Госномер'),
          field(mileage, mileageFocus, 'Пробег'),
          field(purchase, purchaseFocus, 'Цена покупки', number: true),
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
          field(seller, sellerFocus, 'Продавец (имя)'),
          field(sellerPhone, sellerPhoneFocus, 'Телефон продавца',
              number: true),
          field(sellerAddress, sellerAddressFocus, 'Адрес / город'),
          field(notes, notesFocus, 'Примечания', lines: 4),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(
              labelText: 'Статус',
              border: OutlineInputBorder(),
            ),
            items: kStatuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
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
}
class CarDetailsScreen extends StatefulWidget {
  final Car car;
  final VoidCallback onChanged;
  final VoidCallback onDelete;
  final void Function(Car) onDuplicate;

  const CarDetailsScreen({
    super.key,
    required this.car,
    required this.onChanged,
    required this.onDelete,
    required this.onDuplicate,
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
    if (await canLaunchUrl(uri)) await launchUrl(uri);
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

  void saveSale() {
    setState(() {
      widget.car.salePrice = salePrice.text.trim();
      widget.car.saleDate =
          saleDate == null ? todayIso() : dateToIso(saleDate!);
      if (widget.car.sale > 0 && widget.car.status != 'Продан') {
        widget.car.status = 'Продан';
        widget.car.statusChangedAt = todayIso();
      }
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

  void duplicateCar() {
    final copy = widget.car.duplicate();
    widget.onDuplicate(copy);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Создана копия автомобиля')),
    );
    Navigator.pop(context);
  }

  void confirmDeleteCar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить автомобиль?'),
        content: const Text(
          'Автомобиль переместится в корзину. Восстановить можно в течение 30 дней.',
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
            child: const Text('В корзину'),
          ),
        ],
      ),
    );
  }

  Future<void> generateContract() async {
    await showDialog(
      context: context,
      builder: (_) => _ContractDialog(car: widget.car),
    );
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;

    return Scaffold(
      appBar: AppBar(
        title: Text('${car.make} ${car.model}'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') editCar();
              if (value == 'duplicate') duplicateCar();
              if (value == 'contract') generateContract();
              if (value == 'delete') confirmDeleteCar();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Редактировать'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'duplicate',
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Дублировать'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'contract',
                child: ListTile(
                  leading: Icon(Icons.description),
                  title: Text('Сформировать ДКП'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('В корзину'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PhotosBlock(car: car, onChanged: widget.onChanged),
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
                  if (car.isStale)
                    _infoRow(
                      'В статусе',
                      '${car.daysInCurrentStatus} дн. ⚠️',
                    ),
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
          _DocumentsBlock(car: car, onChanged: widget.onChanged),
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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

  Widget financeRow(String title, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : null)),
          Text(money(value),
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : null)),
        ],
      ),
    );
  }
}
class _PhotosBlock extends StatelessWidget {
  final Car car;
  final VoidCallback onChanged;

  const _PhotosBlock({required this.car, required this.onChanged});

  Future<void> _addPhoto(BuildContext context) async {
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
    car.photos.add(newPath);
    onChanged();
  }

  Future<void> _removePhoto(int index) async {
    final path = car.photos[index];
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    car.photos.removeAt(index);
    onChanged();
  }

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
                  onPressed: () => _addPhoto(context),
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
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 8),
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
                                    child: const Icon(
                                        Icons.broken_image),
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => _removePhoto(index),
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

class _DocumentsBlock extends StatelessWidget {
  final Car car;
  final VoidCallback onChanged;

  const _DocumentsBlock({required this.car, required this.onChanged});

  IconData _icon(String type) {
    if (type == 'image') return Icons.image;
    if (type == 'pdf') return Icons.picture_as_pdf;
    return Icons.description;
  }

  Future<void> _pick(BuildContext context, String source) async {
    String? srcPath;
    String name = '';
    String type = 'other';

    if (source == 'camera' || source == 'gallery') {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source == 'camera'
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 2000,
      );
      if (picked == null) return;
      srcPath = picked.path;
      name = p.basename(picked.path);
      type = 'image';
    } else {
      final result = await FilePicker.platform.pickFiles();
      if (result == null) return;
      srcPath = result.files.single.path;
      if (srcPath == null) return;
      name = result.files.single.name;
      final ext = p.extension(name).toLowerCase();
      if (ext == '.pdf') {
        type = 'pdf';
      } else if ([
        '.jpg',
        '.jpeg',
        '.png',
        '.gif',
        '.webp',
        '.heic'
      ].contains(ext)) {
        type = 'image';
      } else {
        type = 'other';
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final docsDir = Directory(p.join(dir.path, 'documents'));
    if (!await docsDir.exists()) await docsDir.create(recursive: true);
    final newPath = p.join(
      docsDir.path,
      'doc_${DateTime.now().microsecondsSinceEpoch}'
      '${p.extension(srcPath)}',
    );
    await File(srcPath).copy(newPath);

    car.attachments.add(
      Attachment(
        id: newId(),
        name: name,
        path: newPath,
        type: type,
        addedAt: todayIso(),
      ),
    );
    onChanged();
  }

  Future<void> _open(BuildContext context, Attachment a) async {
    final file = File(a.path);
    if (!await file.exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл не найден')),
      );
      return;
    }
    if (a.type == 'image') {
      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: InteractiveViewer(child: Image.file(file)),
        ),
      );
    } else {
      try {
        await OpenFilex.open(a.path);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось открыть: $e')),
        );
      }
    }
  }

  Future<void> _remove(Attachment a) async {
    try {
      final f = File(a.path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    car.attachments.removeWhere((x) => x.id == a.id);
    onChanged();
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Сфотографировать'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, 'camera');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Из галереи'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, 'gallery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Выбрать файл (PDF, DOCX…)'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, 'files');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  'Документы',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _showAddMenu(context),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            if (car.attachments.isEmpty)
              const Text('Документов пока нет')
            else
              ...car.attachments.map(
                (a) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _icon(a.type),
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    a.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(a.addedAt),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _remove(a),
                  ),
                  onTap: () => _open(context, a),
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
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setLocal(() => category = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(
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
                child:
                    Text(expense == null ? 'Добавить' : 'Сохранить'),
              ),
            ],
          );
        },
      );
    },
  );
}
class TrashScreen extends StatefulWidget {
  final void Function(Car) onRestore;

  const TrashScreen({super.key, required this.onRestore});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<TrashEntry> trash = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await Storage.loadTrash();
    if (!mounted) return;
    setState(() {
      trash = data;
      loading = false;
    });
  }

  Future<void> _restore(TrashEntry t) async {
    trash.removeWhere((x) => x.car.id == t.car.id);
    await Storage.saveTrash(trash);
    widget.onRestore(t.car);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Автомобиль восстановлен')),
    );
  }

  Future<void> _deleteForever(TrashEntry t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить навсегда?'),
        content: const Text(
          'Автомобиль и все связанные файлы будут удалены без возможности восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    for (final path in t.car.photos) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    for (final a in t.car.attachments) {
      try {
        final f = File(a.path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    trash.removeWhere((x) => x.car.id == t.car.id);
    await Storage.saveTrash(trash);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Корзина (${trash.length})'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : trash.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Корзина пуста',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: trash.length,
                  itemBuilder: (context, index) {
                    final t = trash[index];
                    final car = t.car;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
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
                            const SizedBox(height: 4),
                            Text(
                              'Удалён: ${t.deletedAt}'
                              ' • осталось ${t.daysLeft} дн.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _restore(t),
                                    icon: const Icon(Icons.restore),
                                    label: const Text('Восстановить'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _deleteForever(t),
                                  icon: const Icon(
                                    Icons.delete_forever,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
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
class _ContractDialog extends StatefulWidget {
  final Car car;
  const _ContractDialog({required this.car});

  @override
  State<_ContractDialog> createState() => _ContractDialogState();
}

class _ContractDialogState extends State<_ContractDialog> {
  final sellerFio = TextEditingController();
  final sellerPassport = TextEditingController();
  final sellerAddress = TextEditingController();
  final sellerPhone = TextEditingController();
  final buyerFio = TextEditingController();
  final buyerPassport = TextEditingController();
  final buyerAddress = TextEditingController();
  final buyerPhone = TextEditingController();
  final priceController = TextEditingController();
  final sellerIsMe = ValueNotifier<bool>(true);
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    priceController.text = widget.car.sale > 0
        ? widget.car.sale.toStringAsFixed(0)
        : widget.car.invested.toStringAsFixed(0);
    _load();
  }

  Future<void> _load() async {
    final seller = await Storage.loadSellerData();
    final buyer = await Storage.loadBuyerData();
    sellerFio.text = seller['fio'] ?? '';
    sellerPassport.text = seller['passport'] ?? '';
    sellerAddress.text = seller['address'] ?? '';
    sellerPhone.text = seller['phone'] ?? '';
    buyerFio.text = buyer['fio'] ?? '';
    buyerPassport.text = buyer['passport'] ?? '';
    buyerAddress.text = buyer['address'] ?? '';
    buyerPhone.text = buyer['phone'] ?? '';
    if (!mounted) return;
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    sellerFio.dispose();
    sellerPassport.dispose();
    sellerAddress.dispose();
    sellerPhone.dispose();
    buyerFio.dispose();
    buyerPassport.dispose();
    buyerAddress.dispose();
    buyerPhone.dispose();
    priceController.dispose();
    sellerIsMe.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final sellerData = {
      'fio': sellerFio.text.trim(),
      'passport': sellerPassport.text.trim(),
      'address': sellerAddress.text.trim(),
      'phone': sellerPhone.text.trim(),
    };
    final buyerData = {
      'fio': buyerFio.text.trim(),
      'passport': buyerPassport.text.trim(),
      'address': buyerAddress.text.trim(),
      'phone': buyerPhone.text.trim(),
    };
    await Storage.saveSellerData(sellerData);
    await Storage.saveBuyerData(buyerData);
    await saveContractHtml(widget.car, sellerData, buyerData,
        priceController.text.trim());
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Договор сформирован')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Договор купли-продажи',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Авто: ${widget.car.make} ${widget.car.model}'),
            const SizedBox(height: 12),
            const Divider(),
            const Text(
              'Продавец',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            _dlgField(sellerFio, 'ФИО'),
            _dlgField(sellerPassport, 'Паспорт (серия номер)'),
            _dlgField(sellerAddress, 'Адрес регистрации'),
            _dlgField(sellerPhone, 'Телефон'),
            const SizedBox(height: 12),
            const Divider(),
            const Text(
              'Покупатель',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            _dlgField(buyerFio, 'ФИО'),
            _dlgField(buyerPassport, 'Паспорт (серия номер)'),
            _dlgField(buyerAddress, 'Адрес регистрации'),
            _dlgField(buyerPhone, 'Телефон'),
            const SizedBox(height: 12),
            const Divider(),
            _dlgField(priceController, 'Цена продажи (₽)',
                number: true),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _generate,
                    icon: const Icon(Icons.description),
                    label: const Text('Сформировать'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dlgField(
    TextEditingController c,
    String label, {
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}

Future<void> saveContractHtml(
  Car car,
  Map<String, String> seller,
  Map<String, String> buyer,
  String price,
) async {
  final now = DateTime.now();
  final day = now.day.toString().padLeft(2, '0');
  final month = DateFormat('MMMM', 'ru').format(now);
  final year = now.year;
  final priceNum = double.tryParse(price.replaceAll(',', '.')) ?? 0;
  final priceRub = NumberFormat('#,##0').format(priceNum).replaceAll(',', ' ');
  final priceWords = _numToRussianWords(priceNum.round());

  String row(String label, String value) =>
      '<tr><td class="lbl">$label</td><td>$value</td></tr>';

  final html = '''
<!DOCTYPE html>
<html lang="ru"><head><meta charset="utf-8">
<title>ДКП ${car.make} ${car.model}</title>
<style>
  body{font-family:Georgia,serif;margin:30px;line-height:1.5;color:#000;}
  h1{text-align:center;font-size:18px;margin-bottom:4px;}
  .sub{text-align:center;font-size:14px;margin-bottom:20px;}
  .place{text-align:right;font-size:13px;margin-bottom:18px;}
  p{text-align:justify;font-size:14px;margin:6px 0;}
  table{width:100%;border-collapse:collapse;margin:8px 0 16px;}
  .lbl{width:35%;padding:4px 8px;vertical-align:top;font-weight:bold;}
  td{padding:4px 8px;vertical-align:top;border-bottom:1px solid #ddd;font-size:14px;}
  h3{font-size:15px;margin-top:20px;margin-bottom:6px;}
  .sign{display:flex;justify-content:space-between;margin-top:30px;font-size:14px;}
  .sign div{width:45%;}
  .line{border-bottom:1px solid #000;height:20px;margin-bottom:4px;}
  @media print{body{margin:15mm;}}
</style></head><body>
<h1>ДОГОВОР КУПЛИ-ПРОДАЖИ АВТОМОБИЛЯ</h1>
<div class="sub">№ ${car.id} от $day $month $year</div>
<div class="place">г. __________, $day $month $year</div>

<p>Гражданин(ка) <b>${seller['fio'] ?? ''}</b>, паспорт ${seller['passport'] ?? ''},
зарегистрированный(ая) по адресу: ${seller['address'] ?? ''},
телефон: ${seller['phone'] ?? ''} — именуемый(ая) в дальнейшем «Продавец»,
с одной стороны, и</p>

<p>Гражданин(ка) <b>${buyer['fio'] ?? ''}</b>, паспорт ${buyer['passport'] ?? ''},
зарегистрированный(ая) по адресу: ${buyer['address'] ?? ''},
телефон: ${buyer['phone'] ?? ''} — именуемый(ая) в дальнейшем «Покупатель»,
с другой стороны, заключили настоящий договор о нижеследующем.</p>

<h3>1. Предмет договора</h3>
<p>Продавец передаёт, а Покупатель принимает в собственность транспортное средство:</p>
<table>
${row('Марка, модель', '${car.make} ${car.model}')}
${row('Год выпуска', car.year)}
${row('VIN', car.vin)}
${row('Государственный номер', car.plate)}
${row('Пробег', car.mileage.isEmpty ? '—' : '${car.mileage} км')}
${row('Техническое состояние', 'удовлетворительное')}
</table>

<h3>2. Цена и порядок расчётов</h3>
<p>Стоимость транспортного средства составляет <b>$priceRub ₽</b>
($priceWords).</p>
<p>Денежные средства переданы Продавцу в полном объёме до подписания
настоящего договора.</p>

<h3>3. Передача автомобиля</h3>
<p>Продавец передаёт Покупателю автомобиль, ключи, ПТС, СТС и иные
документы, необходимые для регистрации в ГИБДД. Покупатель обязуется
в течение 10 дней со дня подписания договора обратиться в органы
ГИБДД для перерегистрации транспортного средства.</p>

<h3>4. Прочие условия</h3>
<p>Договор составлен в трёх экземплярах: по одному для Продавца и
Покупателя, третий — для органов ГИБДД. Все экземпляры имеют одинаковую
юридическую силу.</p>

<div class="sign">
  <div>
    <b>Продавец</b>
    <div class="line"></div>
    <div style="font-size:12px;">${seller['fio'] ?? ''}</div>
  </div>
  <div>
    <b>Покупатель</b>
    <div class="line"></div>
    <div style="font-size:12px;">${buyer['fio'] ?? ''}</div>
  </div>
</div>
</body></html>
''';

  final dir = await getApplicationDocumentsDirectory();
  final contractsDir = Directory(p.join(dir.path, 'contracts'));
  if (!await contractsDir.exists()) {
    await contractsDir.create(recursive: true);
  }
  final fileName =
      'ДКП_${car.make}_${car.model}_${DateTime.now().millisecondsSinceEpoch}.html';
  final file = File(p.join(contractsDir.path, fileName));
  await file.writeAsString(html);
  await OpenFilex.open(file.path);
}
String _numToRussianWords(int n) {
  if (n == 0) return 'ноль рублей 00 копеек';
  final units = [
    '', 'один', 'два', 'три', 'четыре', 'пять',
    'шесть', 'семь', 'восемь', 'девять', 'десять',
    'одиннадцать', 'двенадцать', 'тринадцать',
    'четырнадцать', 'пятнадцать', 'шестнадцать',
    'семнадцать', 'восемнадцать', 'девятнадцать'
  ];
  final tens = [
    '', '', 'двадцать', 'тридцать', 'сорок',
    'пятьдесят', 'шестьдесят', 'семьдесят',
    'восемьдесят', 'девяносто'
  ];
  final hundreds = [
    '', 'сто', 'двести', 'триста', 'четыреста',
    'пятьсот', 'шестьсот', 'семьсот', 'восемьсот',
    'девятьсот'
  ];
  final female = [
    '', 'одна', 'две', 'три', 'четыре', 'пять',
    'шесть', 'семь', 'восемь', 'девять', 'десять',
    'одиннадцать', 'двенадцать', 'тринадцать',
    'четырнадцать', 'пятнадцать', 'шестнадцать',
    'семнадцать', 'восемнадцать', 'девятнадцать'
  ];

  String under1000(int num, {bool feminine = false}) {
    final parts = <String>[];
    parts.add(hundreds[num ~/ 100]);
    final rest = num % 100;
    if (rest < 20) {
      parts.add(feminine ? female[rest] : units[rest]);
    } else {
      parts.add(tens[rest ~/ 10]);
      parts.add(feminine ? female[rest % 10] : units[rest % 10]);
    }
    return parts.where((x) => x.isNotEmpty).join(' ');
  }

  final parts = <String>[];
  final millions = n ~/ 1000000;
  final thousands = (n % 1000000) ~/ 1000;
  final rest = n % 1000;

  if (millions > 0) {
    parts.add(under1000(millions));
    final last = millions % 10;
    final lastTwo = millions % 100;
    if (lastTwo >= 11 && lastTwo <= 14) {
      parts.add('миллионов');
    } else if (last == 1) {
      parts.add('миллион');
    } else if (last >= 2 && last <= 4) {
      parts.add('миллиона');
    } else {
      parts.add('миллионов');
    }
  }
  if (thousands > 0) {
    parts.add(under1000(thousands, feminine: true));
    final last = thousands % 10;
    final lastTwo = thousands % 100;
    if (lastTwo >= 11 && lastTwo <= 14) {
      parts.add('тысяч');
    } else if (last == 1) {
      parts.add('тысяча');
    } else if (last >= 2 && last <= 4) {
      parts.add('тысячи');
    } else {
      parts.add('тысяч');
    }
  }
  if (rest > 0) {
    parts.add(under1000(rest));
    final last = rest % 10;
    final lastTwo = rest % 100;
    if (lastTwo >= 11 && lastTwo <= 14) {
      parts.add('рублей');
    } else if (last == 1) {
      parts.add('рубль');
    } else if (last >= 2 && last <= 4) {
      parts.add('рубля');
    } else {
      parts.add('рублей');
    }
  } else {
    parts.add('рублей');
  }
  parts.add('00 копеек');
  final joined = parts.where((x) => x.isNotEmpty).join(' ');
  return joined[0].toUpperCase() + joined.substring(1);
}

Future<void> exportCsv(List<Car> cars) async {
  final buf = StringBuffer();
  buf.writeln(
    'Марка;Модель;Год;VIN;Госномер;Статус;Дата покупки;Дней на складе;'
    'Дней в статусе;Цена покупки;Расходы;Всего вложено;Цена продажи;'
    'Дата продажи;Прибыль',
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
      c.daysInCurrentStatus,
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
