import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.system);

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
  String status;
  String seller;
  String notes;
  String salePrice;
  List<Expense> expenses;

  Car({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.vin,
    required this.plate,
    required this.mileage,
    required this.purchasePrice,
    required this.status,
    required this.seller,
    required this.notes,
    required this.salePrice,
    required this.expenses,
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
      status: (json['status'] ?? 'Куплен') as String,
      seller: (json['seller'] ?? '') as String,
      notes: (json['notes'] ?? '') as String,
      salePrice: (json['salePrice'] ?? '') as String,
      expenses: ((json['expenses'] ?? []) as List)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
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
        'status': status,
        'seller': seller,
        'notes': notes,
        'salePrice': salePrice,
        'expenses': expenses.map((e) => e.toJson()).toList(),
      };

  double get purchase =>
      double.tryParse(purchasePrice.replaceAll(',', '.')) ?? 0;

  double get sale =>
      double.tryParse(salePrice.replaceAll(',', '.')) ?? 0;

  double get expensesTotal =>
      expenses.fold(0, (sum, item) => sum + item.amount);

  double get invested => purchase + expensesTotal;

  double get profit => sale - invested;
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
      category: (json['category'] ?? '') as String,
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

  static const _themeKey = 'theme_mode_v1';

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

String newId() =>
    DateTime.now().microsecondsSinceEpoch.toString();
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Car> cars = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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

  double get totalInvested =>
      cars.fold(0, (sum, car) => sum + car.invested);

  double get totalProfit =>
      cars.fold(0, (sum, car) => sum + car.profit);

  int countStatus(String status) =>
      cars.where((car) => car.status == status).length;

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
          onDelete: () {
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

  String _themeTooltip(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Светлая тема (нажмите для тёмной)';
      case ThemeMode.dark:
        return 'Тёмная тема (нажмите для авто)';
      default:
        return 'Как в системе (нажмите для светлой)';
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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Авто Профит'),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, mode, _) {
              return IconButton(
                tooltip: _themeTooltip(mode),
                onPressed: () => _cycleTheme(mode),
                icon: Icon(_themeIcon(mode)),
              );
            },
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: addCar,
        icon: const Icon(Icons.add),
        label: const Text('Добавить авто'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Панель управления',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Автомобили',
                  value: '${cars.length}',
                  icon: Icons.directions_car,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  title: 'На продаже',
                  value: '${countStatus('На продаже')}',
                  icon: Icons.sell,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Вложено',
                  value: money(totalInvested),
                  icon: Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  title: 'Прибыль',
                  value: money(totalProfit),
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Статусы',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  statusRow('Куплен', countStatus('Куплен')),
                  statusRow('В ремонте', countStatus('В ремонте')),
                  statusRow('Готов к продаже',
                      countStatus('Готов к продаже')),
                  statusRow('На продаже', countStatus('На продаже')),
                  statusRow('Продан', countStatus('Продан')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (cars.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 56,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Автомобилей пока нет',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Нажмите «Добавить авто», чтобы создать первую карточку.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...cars.map(
              (car) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.directions_car),
                  ),
                  title: Text('${car.make} ${car.model}'),
                  subtitle: Text(
                    '${car.year} • ${car.status}\n'
                    'Вложено: ${money(car.invested)}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => openCar(car),
                ),
              ),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget statusRow(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(title),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
  final notes = TextEditingController();

  String status = 'Куплен';

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
      notes.text = c.notes;
      status = c.status;
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
    notes.dispose();
    super.dispose();
  }

  void save() {
    if (make.text.trim().isEmpty ||
        model.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите марку и модель'),
        ),
      );
      return;
    }

    if (isEdit) {
      final c = widget.car!;
      c.make = make.text.trim();
      c.model = model.text.trim();
      c.year = year.text.trim();
      c.vin = vin.text.trim();
      c.plate = plate.text.trim();
      c.mileage = mileage.text.trim();
      c.purchasePrice = purchase.text.trim();
      c.status = status;
      c.seller = seller.text.trim();
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
          status: status,
          seller: seller.text.trim(),
          notes: notes.text.trim(),
          salePrice: '',
          expenses: [],
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
          field(seller, 'Продавец'),
          field(notes, 'Примечания', lines: 4),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(
              labelText: 'Статус',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Куплен',
                child: Text('Куплен'),
              ),
              DropdownMenuItem(
                value: 'В ремонте',
                child: Text('В ремонте'),
              ),
              DropdownMenuItem(
                value: 'Готов к продаже',
                child: Text('Готов к продаже'),
              ),
              DropdownMenuItem(
                value: 'На продаже',
                child: Text('На продаже'),
              ),
              DropdownMenuItem(
                value: 'Продан',
                child: Text('Продан'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => status = value);
              }
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: save,
            icon: const Icon(Icons.save),
            label: Text(
              isEdit
                  ? 'Сохранить изменения'
                  : 'Сохранить автомобиль',
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

  @override
  void initState() {
    super.initState();
    salePrice.text = widget.car.salePrice;
  }

  @override
  void dispose() {
    salePrice.dispose();
    super.dispose();
  }

  void saveSalePrice() {
    setState(() {
      widget.car.salePrice = salePrice.text.trim();
    });
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Цена продажи сохранена')),
    );
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
          'Автомобиль и все его расходы будут удалены. Действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
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

  void showExpenseDialog({Expense? expense}) {
    final category = TextEditingController(
      text: expense?.category ?? '',
    );
    final amount = TextEditingController(
      text: expense != null
          ? expense.amount.toStringAsFixed(0)
          : '',
    );
    final note = TextEditingController(
      text: expense?.note ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            expense == null
                ? 'Добавить расход'
                : 'Изменить расход',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: category,
                  decoration: const InputDecoration(
                    labelText: 'Категория',
                    border: OutlineInputBorder(),
                  ),
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
                  setState(() {
                    widget.car.expenses.removeWhere(
                      (e) => e.id == expense.id,
                    );
                  });
                  widget.onChanged();
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
                if (category.text.trim().isEmpty || value <= 0) {
                  return;
                }
                setState(() {
                  if (expense == null) {
                    widget.car.expenses.add(
                      Expense(
                        id: newId(),
                        category: category.text.trim(),
                        amount: value,
                        note: note.text.trim(),
                      ),
                    );
                  } else {
                    expense.category = category.text.trim();
                    expense.amount = value;
                    expense.note = note.text.trim();
                  }
                });
                widget.onChanged();
                Navigator.pop(dialogContext);
              },
              child: Text(expense == null ? 'Добавить' : 'Сохранить'),
            ),
          ],
        );
      },
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${car.make} ${car.model}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Год: ${car.year}'),
                  Text('VIN: ${car.vin}'),
                  Text('Госномер: ${car.plate}'),
                  Text('Пробег: ${car.mileage}'),
                  Text('Продавец: ${car.seller}'),
                  Text('Статус: ${car.status}'),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Цена продажи',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: salePrice,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Цена продажи',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: saveSalePrice,
                    child: const Text('Сохранить'),
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
                        onPressed: () => showExpenseDialog(),
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
                        title: Text(expense.category),
                        subtitle: Text(
                          expense.note.isEmpty
                              ? 'Нажмите, чтобы изменить'
                              : expense.note,
                        ),
                        trailing: Text(
                          money(expense.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () =>
                            showExpenseDialog(expense: expense),
                      ),
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

String money(double value) {
  return '${value.toStringAsFixed(0)} ₽';
}
