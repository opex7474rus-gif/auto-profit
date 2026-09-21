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
  final f = NumberFormat('#,##0', 'ru_RU');
  return '${f.format(value).replaceAll(',', ' ')} ₽';
}

String formatDate(DateTime d) => DateFormat('dd.MM.yyyy').format(d);

String todayIso() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final List<Car> cars = [];
  bool loading = true;
  late TabController tabController;
  final searchController = TextEditingController();
  String search = '';

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    tabController.dispose();
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

  List<Car> get inStock => cars.where((c) => !c.isSold).toList();

  List<Car> get sold => cars.where((c) => c.isSold).toList();

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
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Импорт данных'),
          content: Text(
            'Найдено ${imported.length} авто.\n\n'
            'Заменить текущие данные или добавить к ним?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Добавить'),
            ),
          ],
        ),
      );
      if (ok == null) return;
      setState(() {
        cars.addAll(imported);
      });
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Авто Профит'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') exportJson();
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
        bottom: TabBar(
          controller: tabController,
          tabs: [
            Tab(text: 'В наличии (${inStock.length})'),
            Tab(text: 'Проданные (${sold.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addCar,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                _carList(_filter(inStock), theme, true),
                _carList(_filter(sold), theme, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _carList(List<Car> list, ThemeData theme, bool isStock) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isStock
                    ? Icons.directions_car_outlined
                    : Icons.check_circle_outline,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                isStock
                    ? 'Нет машин в наличии'
                    : 'Нет проданных машин',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isStock
                    ? 'Нажмите «Добавить», чтобы создать первую карточку.'
                    : 'Машины появятся здесь, когда вы укажете цену продажи.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final car = list[index];
        return _CarListTile(
          car: car,
          onTap: () => openCar(car),
        );
      },
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
                      Text('Вложено: ${money(car.invested)}'),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'На складе $days дн.',
                            style: theme.textTheme.bodySmall,
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
          field(sellerPhone, 'Телефон продавца',
              number: true),
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
    final phone = widget.car.sellerPhone.replaceAll(RegExp(r'[^\d+]'), '');
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
    final theme = Theme.of(context);

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
                  _infoRow(
                    'На складе',
                    '${car.daysInStock} дн.',
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
                    Row(
                      children: [
                        if (car.sellerPhone.isNotEmpty)
                          FilledButton.icon(
                            onPressed: _call,
                            icon: const Icon(Icons.phone),
                            label: const Text('Позвонить'),
                          ),
                        if (car.sellerPhone.isNotEmpty &&
                            car.sellerAddress.isNotEmpty)
                          const SizedBox(width: 8),
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
          _ExpensesBlock(
            car: car,
            onChanged: widget.onChanged,
          ),
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
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : null,
            ),
          ),
          Text(
            money(value),
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : null,
            ),
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
