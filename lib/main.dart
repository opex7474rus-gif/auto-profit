import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const String kSupabaseUrl = 'https://sqawuzstldgjmllwwtci.supabase.co';
const String kSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNxYXd1enN0bGRnam1sbHd3dGNpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAwMzg1NzAsImV4cCI6MjEwNTYxNDU3MH0.2qVrtZ9GnJMFZf8yFRbrjqxKpDWw58bjCxXtRVkJJLo';

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

const List<String> kTagSuggestions = [
  'Срочно продать',
  'Долг',
  'Хорошая',
  'Проблемная',
  'Под клиента',
  'На покраске',
  'Ждёт документы',
];

const int kStaleDays = 30;
const int kReminderDays = 3;
const String kLastCheckKey = 'last_check_v1';
const int kTrashDays = 30;
const double kMinMargin = 30000;
const double kPartnerProfitShare = 0.33;
const Color kSeedColor = Color(0xFF4A4FC7);

const Map<String, List<String>> kCarCatalog = {
  'Lada': ['Granta', 'Vesta', 'Largus', 'Niva', 'XRAY', 'Kalina', 'Priora'],
  'Toyota': ['Camry', 'Corolla', 'RAV4', 'Land Cruiser', 'Highlander'],
  'Kia': ['Rio', 'Sportage', 'Optima', 'Ceed', 'Sorento', 'Soul'],
  'Hyundai': ['Solaris', 'Creta', 'Tucson', 'Santa Fe', 'Elantra'],
  'Volkswagen': ['Polo', 'Tiguan', 'Passat', 'Golf', 'Jetta'],
  'Renault': ['Logan', 'Duster', 'Sandero', 'Kaptur', 'Arkana'],
  'Nissan': ['Qashqai', 'X-Trail', 'Juke', 'Almera', 'Murano'],
  'Ford': ['Focus', 'Mondeo', 'Kuga', 'Explorer', 'Transit'],
  'Skoda': ['Octavia', 'Rapid', 'Superb', 'Kodiaq', 'Fabia'],
  'BMW': ['3 серия', '5 серия', '7 серия', 'X1', 'X3', 'X5'],
  'Mercedes-Benz': ['C-класс', 'E-класс', 'GLA', 'GLC', 'GLE'],
  'Audi': ['A3', 'A4', 'A6', 'Q3', 'Q5', 'Q7'],
  'Mazda': ['3', '6', 'CX-5', 'CX-9'],
  'Chevrolet': ['Cruze', 'Aveo', 'Lacetti', 'Niva', 'Captiva'],
  'Mitsubishi': ['Lancer', 'Outlander', 'ASX', 'Pajero'],
  'Opel': ['Astra', 'Corsa', 'Insignia', 'Mokka'],
  'Peugeot': ['308', '408', '3008', '5008'],
  'Citroen': ['C4', 'C5', 'Berlingo', 'C3'],
  'Honda': ['Civic', 'Accord', 'CR-V', 'Pilot'],
  'Suzuki': ['Vitara', 'SX4', 'Jimny', 'Swift'],
  'Chery': ['Tiggo 4', 'Tiggo 7', 'Tiggo 8', 'Arrizo 5'],
  'Haval': ['H6', 'H9', 'Jolion', 'F7', 'Dargo'],
  'Geely': ['Coolray', 'Atlas', 'Tugella', 'Monjaro'],
  'Datsun': ['on-DO', 'mi-DO'],
  'Daewoo': ['Nexia', 'Matiz', 'Gentra'],
  'Ravon': ['Nexia R3', 'R2', 'R4'],
  'УАЗ': ['Patriot', 'Hunter', 'Profi'],
  'ГАЗ': ['Газель', 'Соболь', 'Волга'],
};

const Map<String, String> kDefaultBuyerData = {
  'fio': '',
  'passport': '',
  'address': '',
  'phone': '',
};
class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: kSeedColor,
      brightness: Brightness.light,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      cardTheme: _cardTheme(scheme),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: kSeedColor,
      brightness: Brightness.dark,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFF14151A),
      cardTheme: _cardTheme(scheme),
    );
  }

  static CardThemeData _cardTheme(ColorScheme scheme) {
    return CardThemeData(
      elevation: 0,
      color: scheme.surface,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: EdgeInsets.zero,
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
        space: 20,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: scheme.surface,
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );
  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: kSupabaseAnonKey,
  );
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
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const HomeScreen();
        }
        return const AuthScreen();
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
  String partnerInvestment;
  List<String> tags;
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
    required this.partnerInvestment,
    required this.tags,
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
      partnerInvestment: (json['partnerInvestment'] ?? '') as String,
      tags: ((json['tags'] ?? []) as List)
          .map((e) => e.toString())
          .toList(),
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
        'partnerInvestment': partnerInvestment,
        'tags': tags,
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'photos': photos,
        'attachments': attachments.map((a) => a.toJson()).toList(),
      };
      Car duplicate() {
    final now = DateTime.now();
    final iso = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return Car(
      id: now.microsecondsSinceEpoch.toString(),
      make: make,
      model: model,
      year: year,
      vin: '',
      plate: '',
      mileage: mileage,
      purchasePrice: purchasePrice,
      purchaseDate: iso,
      status: 'Куплен',
      statusChangedAt: iso,
      seller: seller,
      sellerPhone: sellerPhone,
      sellerAddress: sellerAddress,
      notes: notes,
      salePrice: '',
      saleDate: '',
      partnerInvestment: partnerInvestment,
      tags: List<String>.from(tags),
      expenses: [],
      photos: [],
      attachments: [],
    );
  }

  double get purchase =>
      double.tryParse(purchasePrice.replaceAll(',', '.')) ?? 0;

  double get sale =>
      double.tryParse(salePrice.replaceAll(',', '.')) ?? 0;

  double get partnerAmount =>
      double.tryParse(partnerInvestment.replaceAll(',', '.')) ?? 0;

  double get expensesTotal =>
      expenses.fold(0, (sum, item) => sum + item.amount);

  double get invested => purchase + expensesTotal;

  double get profit => sale - invested;

  double get partnerProfit =>
      partnerAmount > 0 ? profit * kPartnerProfitShare : 0;

  double get myProfit => profit - partnerProfit;

  bool get isSold => sale > 0;

  double get breakEvenPrice => invested + kMinMargin;

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

bool isCloudUrl(String s) => s.startsWith('http');

bool isLocalMarker(String s) => s.startsWith('local:');

String localPathOf(String s) {
  if (isLocalMarker(s)) return s.substring(6);
  return s;
}
class Storage {
  static const _key = 'cars_v1';
  static const _trashKey = 'cars_trash_v1';
  static const _themeKey = 'theme_mode_v1';
  static const _sellerKey = 'seller_data_v1';
  static const _buyerKey = 'buyer_data_v1';
  static const _pendingKey = 'pending_sync_v1';

  static SupabaseClient get _db => Supabase.instance.client;
  static String? get _uid => _db.auth.currentUser?.id;

  static Future<String?> uploadFile({
    required String bucket,
    required String localPath,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) return null;
      final f = File(localPath);
      if (!await f.exists()) return null;
      final ext = p.extension(localPath).toLowerCase();
      final name =
          '$uid/${DateTime.now().microsecondsSinceEpoch}${ext.isEmpty ? '.bin' : ext}';
      await _db.storage.from(bucket).upload(name, f);
      return _db.storage.from(bucket).getPublicUrl(name);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_pendingKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setPending(bool v) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pendingKey, v);
    } catch (_) {}
  }

  static Map<String, dynamic> _carToRow(Car c) {
    final uid = _uid;
    return {
      if (uid != null) 'user_id': uid,
      'id': c.id,
      'make': c.make,
      'model': c.model,
      'year': c.year,
      'vin': c.vin,
      'plate': c.plate,
      'mileage': c.mileage,
      'purchase_price': c.purchasePrice,
      'purchase_date': c.purchaseDate,
      'status': c.status,
      'status_changed_at': c.statusChangedAt,
      'seller': c.seller,
      'seller_phone': c.sellerPhone,
      'seller_address': c.sellerAddress,
      'notes': c.notes,
      'sale_price': c.salePrice,
      'sale_date': c.saleDate,
      'partner_investment': c.partnerInvestment,
      'tags': c.tags,
      'expenses': c.expenses.map((e) => e.toJson()).toList(),
      'photos': c.photos,
      'attachments': c.attachments.map((a) => a.toJson()).toList(),
    };
  }

  static Car _rowToCar(Map<String, dynamic> r) {
    return Car(
      id: (r['id'] ?? '') as String,
      make: (r['make'] ?? '') as String,
      model: (r['model'] ?? '') as String,
      year: (r['year'] ?? '') as String,
      vin: (r['vin'] ?? '') as String,
      plate: (r['plate'] ?? '') as String,
      mileage: (r['mileage'] ?? '') as String,
      purchasePrice: (r['purchase_price'] ?? '') as String,
      purchaseDate: (r['purchase_date'] ?? '') as String,
      status: (r['status'] ?? 'Куплен') as String,
      statusChangedAt: (r['status_changed_at'] ?? '') as String,
      seller: (r['seller'] ?? '') as String,
      sellerPhone: (r['seller_phone'] ?? '') as String,
      sellerAddress: (r['seller_address'] ?? '') as String,
      notes: (r['notes'] ?? '') as String,
      salePrice: (r['sale_price'] ?? '') as String,
      saleDate: (r['sale_date'] ?? '') as String,
      partnerInvestment: (r['partner_investment'] ?? '') as String,
      tags: ((r['tags'] ?? []) as List)
          .map((e) => e.toString())
          .toList(),
      expenses: ((r['expenses'] ?? []) as List)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList(),
      photos: ((r['photos'] ?? []) as List)
          .map((e) => e.toString())
          .toList(),
      attachments: ((r['attachments'] ?? []) as List)
          .map((e) => Attachment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
    static Future<List<Car>> load() async {
  List<Car> local = [];
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List;
      local = list
          .map((e) => Car.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  } catch (_) {}

  try {
    if (_uid != null) {
      final rows = await _db
          .from('cars')
          .select()
          .order('created_at', ascending: true);
      final cars = (rows as List)
          .map((r) => _rowToCar(r as Map<String, dynamic>))
          .toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(cars.map((c) => c.toJson()).toList()),
      );

      if (await hasPending()) {
        await save(cars);
      }

      return cars;
    }
  } catch (_) {}

  return local;
}

static Future<void> save(List<Car> cars) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(cars.map((c) => c.toJson()).toList()),
    );
  } catch (_) {}

  try {
    if (_uid == null) return;

    bool allUploaded = true;

    for (final c in cars) {
      final newPhotos = <String>[];
      for (final ph in c.photos) {
        if (isLocalMarker(ph)) {
          final url = await uploadFile(
            bucket: 'photos',
            localPath: localPathOf(ph),
          );
          if (url != null) {
            newPhotos.add(url);
          } else {
            newPhotos.add(ph);
            allUploaded = false;
          }
        } else {
          newPhotos.add(ph);
        }
      }
      c.photos = newPhotos;

      for (final a in c.attachments) {
        if (isLocalMarker(a.path)) {
          final url = await uploadFile(
            bucket: 'documents',
            localPath: localPathOf(a.path),
          );
          if (url != null) {
            a.path = url;
          } else {
            allUploaded = false;
          }
        }
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(cars.map((c) => c.toJson()).toList()),
      );
    } catch (_) {}

    final existingRows = await _db.from('cars').select('id');
    final existingIds = (existingRows as List)
        .map((r) => (r['id'] ?? '').toString())
        .toSet();

    if (cars.isNotEmpty) {
      final rows = cars.map((c) => _carToRow(c)).toList();
      await _db.from('cars').upsert(rows);
    }

    final localIds = cars.map((c) => c.id).toSet();
    final toDelete = existingIds.difference(localIds).toList();
    if (toDelete.isNotEmpty) {
      await _db.from('cars').delete().inFilter('id', toDelete);
    }

    await setPending(!allUploaded);
  } catch (_) {
    await setPending(true);
  }
}
      static Future<void> clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      await prefs.remove(_trashKey);
      await prefs.remove(_pendingKey);
    } catch (_) {}
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
        for (final path in t.car.photos) {
          if (isCloudUrl(path)) continue;
          try {
            final f = File(localPathOf(path));
            if (await f.exists()) await f.delete();
          } catch (_) {}
        }
        for (final a in t.car.attachments) {
          if (isCloudUrl(a.path)) continue;
          try {
            final f = File(localPathOf(a.path));
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

String carsLabel(int n) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 14) return 'машин';
  if (mod10 == 1) return 'машина';
  if (mod10 >= 2 && mod10 <= 4) return 'машины';
  return 'машин';
}

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

Future<void> exportCsv(List<Car> cars) async {
  final buf = StringBuffer();
  buf.writeln(
    'Марка;Модель;Год;VIN;Госномер;Статус;Метки;Дата покупки;'
    'Дней на складе;Цена покупки;Расходы;Всего вложено;'
    'Доля партнёра;Прибыль партнёра;Цена продажи;Дата продажи;Прибыль',
  );
  for (final c in cars) {
    buf.writeln([
      c.make,
      c.model,
      c.year,
      c.vin,
      c.plate,
      c.status,
      c.tags.join(', '),
      c.purchaseDate,
      c.daysInStock,
      c.purchase.toStringAsFixed(0),
      c.expensesTotal.toStringAsFixed(0),
      c.invested.toStringAsFixed(0),
      c.partnerAmount.toStringAsFixed(0),
      c.partnerProfit.toStringAsFixed(0),
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

class BrandStat {
  final String name;
  final int count;
  final double totalProfit;
  final double avgProfit;
  final double avgDays;
  BrandStat({
    required this.name,
    required this.count,
    required this.totalProfit,
    required this.avgProfit,
    required this.avgDays,
  });
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

  double get averageProfitThisMonth => soldThisMonthCount == 0
      ? 0
      : profitThisMonth / soldThisMonthCount;

  double get totalPurchase => cars.fold(0, (s, c) => s + c.purchase);
  double get totalExpenses =>
      cars.fold(0, (s, c) => s + c.expensesTotal);
  double get totalInvested => totalPurchase + totalExpenses;

  double get totalPurchaseStock =>
      stockCars.fold(0, (s, c) => s + c.purchase);
  double get totalExpensesStock =>
      stockCars.fold(0, (s, c) => s + c.expensesTotal);
  double get totalInvestedStock =>
      totalPurchaseStock + totalExpensesStock;

  double get totalPurchaseSold =>
      soldCars.fold(0, (s, c) => s + c.purchase);
  double get totalExpensesSold =>
      soldCars.fold(0, (s, c) => s + c.expensesTotal);
  double get totalInvestedSold =>
      totalPurchaseSold + totalExpensesSold;

  double get totalRevenue => soldCars.fold(0, (s, c) => s + c.sale);
  double get totalProfit => soldCars.fold(0, (s, c) => s + c.profit);

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

  List<Car> get partnerCars =>
      cars.where((c) => c.partnerAmount > 0).toList();
  List<Car> get partnerStock =>
      stockCars.where((c) => c.partnerAmount > 0).toList();
  List<Car> get partnerSold =>
      soldCars.where((c) => c.partnerAmount > 0).toList();

  int get partnerCarsCount => partnerCars.length;
  int get partnerCarsCountStock => partnerStock.length;
  int get partnerCarsCountSold => partnerSold.length;

  double get totalPartnerInvestment =>
      partnerCars.fold(0.0, (s, c) => s + c.partnerAmount);
  double get totalPartnerStock =>
      partnerStock.fold(0.0, (s, c) => s + c.partnerAmount);
  double get totalPartnerSold =>
      partnerSold.fold(0.0, (s, c) => s + c.partnerAmount);

  double get partnerProfitShare =>
      partnerSold.fold(0.0, (s, c) => s + c.partnerProfit);

  double get myProfitShare => totalProfit - partnerProfitShare;
      double get potentialProfit {
    if (soldCars.isEmpty) return 0;
    final totalInvestedSoldLocal =
        soldCars.fold(0.0, (s, c) => s + c.invested);
    if (totalInvestedSoldLocal == 0) return 0;
    final margin = totalProfit / totalInvestedSoldLocal;
    return totalInvestedStock * margin;
  }

  List<BrandStat> get brandStats {
    final map = <String, List<Car>>{};
    for (final c in soldCars) {
      final brand = c.make.trim().isEmpty ? 'Без марки' : c.make.trim();
      map.putIfAbsent(brand, () => []).add(c);
    }
    final list = map.entries.map((e) {
      final listCars = e.value;
      final total = listCars.fold(0.0, (s, c) => s + c.profit);
      final avg = listCars.isEmpty ? 0.0 : total / listCars.length;
      final avgD = listCars.isEmpty
          ? 0.0
          : listCars.map((c) => c.daysInStock).reduce((a, b) => a + b) /
              listCars.length;
      return BrandStat(
        name: e.key,
        count: listCars.length,
        totalProfit: total,
        avgProfit: avg,
        avgDays: avgD,
      );
    }).toList();
    list.sort((a, b) => b.totalProfit.compareTo(a.totalProfit));
    return list;
  }

  Car? get bestCar {
    if (soldCars.isEmpty) return null;
    return soldCars.reduce((a, b) => a.profit >= b.profit ? a : b);
  }

  Car? get worstCar {
    if (soldCars.isEmpty) return null;
    return soldCars.reduce((a, b) => a.profit <= b.profit ? a : b);
  }

  Map<String, int> get statusCounts {
    final map = <String, int>{};
    for (final s in kStatuses) {
      map[s] = cars.where((c) => c.status == s).length;
    }
    return map;
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
Color statusColor(String status) {
  switch (status) {
    case 'Куплен':
      return const Color(0xFF3B82F6);
    case 'В ремонте':
      return const Color(0xFFF59E0B);
    case 'Готов к продаже':
      return const Color(0xFF8B5CF6);
    case 'На продаже':
      return const Color(0xFF06B6D4);
    case 'Продан':
      return const Color(0xFF10B981);
    default:
      return Colors.grey;
  }
}

IconData statusIcon(String status) {
  switch (status) {
    case 'Куплен':
      return Icons.shopping_cart_outlined;
    case 'В ремонте':
      return Icons.build_outlined;
    case 'Готов к продаже':
      return Icons.checklist_rtl;
    case 'На продаже':
      return Icons.sell_outlined;
    case 'Продан':
      return Icons.check_circle_outline;
    default:
      return Icons.circle_outlined;
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon(status), size: compact ? 11 : 13, color: c),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: c,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool highlight;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: highlight
                  ? [color, color.withValues(alpha: 0.78)]
                  : [
                      color.withValues(alpha: isDark ? 0.18 : 0.10),
                      color.withValues(alpha: isDark ? 0.08 : 0.03),
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.25 : 0.15),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: highlight
                          ? Colors.white.withValues(alpha: 0.22)
                          : color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: highlight ? Colors.white : color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: highlight
                            ? Colors.white.withValues(alpha: 0.92)
                            : theme.colorScheme.onSurfaceVariant,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: highlight
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: highlight
                        ? Colors.white.withValues(alpha: 0.85)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
class SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.text,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 15,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class PaddedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  const PaddedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(padding: padding, child: child),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
class ExpensesTopCard extends StatelessWidget {
  final List<CategoryStat> stats;
  final double totalExpenses;

  const ExpensesTopCard({
    super.key,
    required this.stats,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return PaddedCard(
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            const Text('Расходов ещё нет'),
          ],
        ),
      );
    }
    const palette = [
      Color(0xFF4A4FC7),
      Color(0xFFFF7A45),
      Color(0xFF9B5DE5),
      Color(0xFF06B6D4),
      Color(0xFFF59E0B),
    ];
    return PaddedCard(
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
                        minHeight: 7,
                        backgroundColor:
                            color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class MonthlyChart extends StatelessWidget {
  final List<MonthStat> stats;
  const MonthlyChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();
    final maxProfit = stats
        .map((m) => m.profit.abs())
        .fold<double>(0, (a, b) => a > b ? a : b);
    final theme = Theme.of(context);
    final positiveColor = const Color(0xFF10B981);
    final negativeColor = const Color(0xFFEF4444);

    return PaddedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: stats.map((m) {
                final positive = m.profit >= 0;
                final value = maxProfit == 0
                    ? 0.0
                    : (m.profit.abs() / maxProfit);
                final barHeight = 12 + 88 * value;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            m.profit == 0 ? '—' : moneyShort(m.profit),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: positive
                                  ? positiveColor
                                  : negativeColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: positive
                                  ? [
                                      positiveColor,
                                      positiveColor.withValues(alpha: 0.6),
                                    ]
                                  : [
                                      negativeColor,
                                      negativeColor.withValues(alpha: 0.6),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          m.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Прибыль по месяцам (последние 6)',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class BestWorstCard extends StatelessWidget {
  final Car? best;
  final Car? worst;

  const BestWorstCard({super.key, required this.best, required this.worst});

  @override
  Widget build(BuildContext context) {
    if (best == null && worst == null) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _miniCard(
            context,
            title: 'Лучшая',
            car: best,
            icon: Icons.emoji_events_outlined,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniCard(
            context,
            title: 'Худшая',
            car: worst,
            icon: Icons.trending_down,
            color: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _miniCard(
    BuildContext context, {
    required String title,
    required Car? car,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (car != null) ...[
            Text(
              '${car.make} ${car.model}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              money(car.profit),
              style: TextStyle(
                color: car.profit >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ] else
            const Text('—'),
        ],
      ),
    );
  }
}
class AnalyticsSection extends StatefulWidget {
  final Analytics analytics;
  const AnalyticsSection({super.key, required this.analytics});

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
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.38,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            KpiCard(
              title: 'Прибыль всего',
              value: moneyShort(a.totalProfit),
              subtitle:
                  '${a.soldAllTimeCount} ${carsLabel(a.soldAllTimeCount)}',
              icon: Icons.trending_up,
              color: a.totalProfit >= 0
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              highlight: true,
            ),
            KpiCard(
              title: 'Прибыль за месяц',
              value: moneyShort(a.profitThisMonth),
              subtitle: '${a.soldThisMonthCount} за месяц',
              icon: Icons.calendar_today_outlined,
              color: const Color(0xFF4A4FC7),
            ),
            KpiCard(
              title: 'В наличии',
              value: '${a.stockCars.length}',
              subtitle: moneyShort(a.totalInvestedStock),
              icon: Icons.directions_car_filled_outlined,
              color: const Color(0xFFFF7A45),
            ),
            KpiCard(
              title: 'Доля партнёра',
              value: a.partnerCarsCountStock == 0
                  ? '—'
                  : moneyShort(a.totalPartnerStock),
              subtitle: a.partnerCarsCountStock == 0
                  ? 'нигде не указана'
                  : 'в ${a.partnerCarsCountStock} '
                      '${carsLabel(a.partnerCarsCountStock)}',
              icon: Icons.handshake_outlined,
              color: const Color(0xFF9B5DE5),
            ),
            KpiCard(
              title: 'Прибыль партнёра',
              value: a.partnerProfitShare == 0
                  ? '—'
                  : moneyShort(a.partnerProfitShare),
              subtitle: 'Вам: ${moneyShort(a.myProfitShare)}',
              icon: Icons.account_balance_outlined,
              color: const Color(0xFF06B6D4),
            ),
            KpiCard(
              title: 'Рентабельность',
              value: a.soldCars.isEmpty
                  ? '—'
                  : '${a.profitability.toStringAsFixed(1)}%',
              subtitle: 'прибыль / вложено',
              icon: Icons.percent,
              color: const Color(0xFFEC4899),
            ),
            KpiCard(
              title: 'Средняя за месяц',
              value: moneyShort(a.averageProfitThisMonth),
              subtitle: 'с машины в этом месяце',
              icon: Icons.calculate_outlined,
              color: const Color(0xFF0EA5E9),
            ),
            KpiCard(
              title: 'Средняя всего',
              value: moneyShort(a.averageProfit),
              subtitle: 'с машины за всё время',
              icon: Icons.attach_money,
              color: const Color(0xFF8B5CF6),
            ),
          ],
        ),
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
            label: 'Прибыль партнёра (33%)',
            value: money(a.partnerProfitShare),
            valueColor: const Color(0xFF9B5DE5),
          ),
          DetailRow(
            label: 'Ваша прибыль (67%)',
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
        value: '${a.profitability.toStringAsFixed(1)}%',
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
  final userEmail =
      Supabase.instance.client.auth.currentUser?.email ?? '';

  return Scaffold(
    appBar: AppBar(
      title: const Text('Авто Профит'),
      actions: [
        PopupMenuButton<String>(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onSelected: (value) {
            if (value == 'export') exportJson();
            if (value == 'csv') exportCsv(cars);
            if (value == 'import') importJson();
            if (value == 'trash') openTrash();
            if (value == 'history') openHistory();
            if (value == 'logout') _logout();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'account',
              enabled: false,
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(
                  userEmail.isEmpty ? 'Аккаунт' : userEmail,
                  style: const TextStyle(fontSize: 12.5),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'history',
              child: ListTile(
                leading: Icon(Icons.history),
                title: Text('История покупок/продаж'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.upload_file_outlined),
                title: Text('Экспорт JSON'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'csv',
              child: ListTile(
                leading: Icon(Icons.table_chart_outlined),
                title: Text('Экспорт CSV (Excel)'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'import',
              child: ListTile(
                leading: Icon(Icons.download_outlined),
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
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('Выйти из аккаунта'),
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
      icon: const Icon(Icons.add_rounded),
      label: const Text('Добавить'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    body: CustomScrollView(
      slivers: [
        if (showCheckReminder)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.18),
                    const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF59E0B)
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Прошло $kReminderDays дня. Проверьте машины на складе.',
                      style: const TextStyle(fontSize: 13.5),
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
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEF4444).withValues(alpha: 0.16),
                    const Color(0xFFEF4444).withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFEF4444)
                      .withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${a.staleCars.length} машин(ы) без изменения статуса больше $kStaleDays дней',
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
                    SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    text: 'Аналитика',
                    icon: Icons.insights_outlined,
                  ),
                  AnalyticsSection(analytics: a),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
            sliver: SliverToBoxAdapter(
              child: StatusesCard(analytics: a),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: searchController,
                onChanged: (v) => setState(() => search = v),
                decoration: InputDecoration(
                  hintText: 'Поиск: марка, VIN, госномер, тег…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 22),
                  suffixIcon: search.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            searchController.clear();
                            setState(() => search = '');
                          },
                        ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            sliver: SliverToBoxAdapter(
              child: _modeTabs(a),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 6, 14, 4),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Icon(
                    listMode == 'stock'
                        ? Icons.warehouse_outlined
                        : Icons.inventory_2_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      listMode == 'stock'
                          ? 'В наличии · ${visible.length}'
                          : 'Проданные · ${visible.length}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.sort_rounded),
                    tooltip: 'Сортировка',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
              child: EmptyState(
                icon: listMode == 'stock'
                    ? Icons.directions_car_outlined
                    : Icons.check_circle_outline,
                title: search.isNotEmpty
                    ? 'Ничего не найдено'
                    : listMode == 'stock'
                        ? 'Нет машин в наличии'
                        : 'Нет проданных машин',
                subtitle: listMode == 'stock'
                    ? 'Нажмите «Добавить», чтобы создать первую карточку'
                    : null,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
              sliver: SliverList.builder(
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final car = visible[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: CarListTile(
                      car: car,
                      onTap: () => openCar(car),
                      onQuickExpense: () async {
                        await showExpenseDialog(
                          context: context,
                          car: car,
                          onChanged: () {
                            setState(() {});
                            _persist();
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _modeTabs(Analytics a) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: ModeTab(
              label: 'В наличии',
              count: a.stockCars.length,
              selected: listMode == 'stock',
              onTap: () => setState(() => listMode = 'stock'),
            ),
          ),
          Expanded(
            child: ModeTab(
              label: 'Проданные',
              count: a.soldCars.length,
              selected: listMode == 'sold',
              onTap: () => setState(() => listMode = 'sold'),
            ),
          ),
        ],
      ),
    );
  }
}
class ModeTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const ModeTab({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color:
                selected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              '$label · $count',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StatusesCard extends StatelessWidget {
  final Analytics analytics;
  const StatusesCard({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final a = analytics;
    return PaddedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Автомобили по статусам',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...kStatuses.map((status) {
            final count = a.statusCounts[status] ?? 0;
            final c = statusColor(status);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: c,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
class CarListTile extends StatelessWidget {
  final Car car;
  final VoidCallback onTap;
  final VoidCallback onQuickExpense;

  const CarListTile({
    super.key,
    required this.car,
    required this.onTap,
    required this.onQuickExpense,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photos = car.photos;
    final days = car.daysInStock;

    Color daysColor = const Color(0xFF10B981);
    if (car.isSold) {
      daysColor = Colors.blueGrey;
    } else if (days >= 60) {
      daysColor = const Color(0xFFEF4444);
    } else if (days >= 30) {
      daysColor = const Color(0xFFF59E0B);
    }

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        onLongPress: onQuickExpense,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant
                  .withValues(alpha: 0.5),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhotoThumb(
                path: photos.isNotEmpty ? photos.first : null,
              ),
              const SizedBox(width: 14),
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
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (car.isStale)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Text(
                              'Залежалась',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    StatusChip(status: car.status, compact: true),
                    if (car.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: car.tags.take(3).map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer
                                  .withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: theme
                                    .colorScheme.onSecondaryContainer,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (car.isSold)
                      Row(
                        children: [
                          Icon(
                            car.profit >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 15,
                            color: car.profit >= 0
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            money(car.profit),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: car.profit >= 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _miniInfo(
                              theme,
                              label: 'Вложено',
                              value: money(car.invested),
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                          ),
                          if (car.partnerAmount > 0)
                            Expanded(
                              child: _miniInfo(
                                theme,
                                label: 'Партнёр',
                                value: money(car.partnerAmount),
                                icon: Icons.handshake_outlined,
                                color: const Color(0xFF9B5DE5),
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
                            color: daysColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'На складе $days дн.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: daysColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniInfo(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    final c = color ?? theme.colorScheme.primary;
    return Row(
      children: [
        Icon(icon, size: 13, color: c.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PhotoThumb extends StatelessWidget {
  final String? path;
  const PhotoThumb({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 84.0;

    if (path == null || path!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.14),
              theme.colorScheme.primary.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.directions_car_rounded,
          size: 40,
          color: theme.colorScheme.primary,
        ),
      );
    }

    Widget img;
    if (isCloudUrl(path!)) {
      img = Image.network(
        path!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.broken_image_outlined),
        ),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    } else {
      final file = File(localPathOf(path!));
      img = file.existsSync()
          ? Image.file(file, fit: BoxFit.cover)
          : Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image_outlined),
            );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(width: size, height: size, child: img),
    );
  }
}
class AutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final Iterable<String> Function(String) optionsBuilder;
  final VoidCallback? onChangedCallback;

  const AutocompleteField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.optionsBuilder,
    this.onChangedCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
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
              elevation: 6,
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxHeight: 220, maxWidth: 320),
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
                          horizontal: 16,
                          vertical: 13,
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
  final partnerInvestment = TextEditingController();

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
  final partnerFocus = FocusNode();

  String status = 'Куплен';
  DateTime? purchaseDate;
  final Set<String> tags = {};

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
      partnerInvestment.text = c.partnerInvestment;
      status = c.status;
      purchaseDate = c.purchaseDateTime;
      tags.addAll(c.tags);
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
    partnerInvestment.dispose();
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
    partnerFocus.dispose();
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

  Future<void> _addCustomTag() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Свой тег'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Название'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => tags.add(result));
    }
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
      c.partnerInvestment = partnerInvestment.text.trim();
      c.tags = tags.toList();
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
          partnerInvestment: partnerInvestment.text.trim(),
          tags: tags.toList(),
          expenses: [],
          photos: [],
          attachments: [],
        ),
      );
    }
    Navigator.pop(context);
  }

  Widget _field(
    TextEditingController controller,
    FocusNode focusNode,
    String label, {
    bool number = false,
    int lines = 1,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: lines,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTagOptions = <String>{
      ...kTagSuggestions,
      ...tags,
    }.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Редактировать авто' : 'Новый автомобиль',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          const SectionTitle(
            text: 'Автомобиль',
            icon: Icons.directions_car_outlined,
          ),
          AutocompleteField(
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
          AutocompleteField(
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
                return all
                    .where((m) => m.toLowerCase().contains(lower));
              }
              final models = kCarCatalog[brand] ?? [];
              return models
                  .where((m) => m.toLowerCase().contains(lower));
            },
          ),
          AutocompleteField(
            controller: year,
            focusNode: yearFocus,
            label: 'Год',
            optionsBuilder: (q) =>
                kYearList.where((y) => y.startsWith(q)),
          ),
          _field(vin, vinFocus, 'VIN',
              icon: Icons.confirmation_number_outlined),
          _field(plate, plateFocus, 'Госномер',
              icon: Icons.directions_car_outlined),
          _field(mileage, mileageFocus, 'Пробег',
              icon: Icons.speed_outlined),
          const SectionTitle(
            text: 'Финансы',
            icon: Icons.account_balance_wallet_outlined,
          ),
          _field(purchase, purchaseFocus, 'Цена покупки',
              number: true, icon: Icons.attach_money),
          _field(
            partnerInvestment,
            partnerFocus,
            'Доля партнёра (₽) — прибыль 33%',
            number: true,
            icon: Icons.handshake_outlined,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: pickPurchaseDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Дата покупки',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  purchaseDate == null
                      ? 'Не указана'
                      : formatDate(purchaseDate!),
                ),
              ),
            ),
          ),
          const SectionTitle(
            text: 'Продавец',
            icon: Icons.person_outline,
          ),
          _field(seller, sellerFocus, 'Имя',
              icon: Icons.person_outline),
          _field(sellerPhone, sellerPhoneFocus, 'Телефон',
              number: true, icon: Icons.phone_outlined),
          _field(sellerAddress, sellerAddressFocus, 'Адрес / город',
              icon: Icons.location_on_outlined),
          const SectionTitle(
            text: 'Прочее',
            icon: Icons.notes_outlined,
          ),
          _field(notes, notesFocus, 'Примечания', lines: 4),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(
              labelText: 'Статус',
              prefixIcon: Icon(Icons.flag_outlined, size: 20),
            ),
            items: kStatuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => status = value);
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Метки',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...allTagOptions.map(
                (t) => FilterChip(
                  label: Text(t),
                  selected: tags.contains(t),
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        tags.add(t);
                      } else {
                        tags.remove(t);
                      }
                    });
                  },
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('Свой'),
                onPressed: _addCustomTag,
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: save,
            icon: const Icon(Icons.check_rounded),
            label: Text(
              isEdit ? 'Сохранить изменения' : 'Сохранить автомобиль',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
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
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
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
      builder: (_) => ContractDialog(car: widget.car),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
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
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Редактировать'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'duplicate',
                child: ListTile(
                  leading: Icon(Icons.copy_outlined),
                  title: Text('Дублировать'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'contract',
                child: ListTile(
                  leading: Icon(Icons.description_outlined),
                  title: Text('Сформировать ДКП'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline,
                      color: Color(0xFFEF4444)),
                  title: Text('В корзину',
                      style: TextStyle(color: Color(0xFFEF4444))),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          PhotosBlock(car: car, onChanged: widget.onChanged),
          const SizedBox(height: 12),
          PaddedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${car.make} ${car.model}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    StatusChip(status: car.status),
                  ],
                ),
                if (car.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: car.tags
                        .map(
                          (t) => Chip(
                            label: Text(
                              t,
                              style: const TextStyle(fontSize: 11.5),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                ],
                const Divider(),
                _infoRow('Год', car.year),
                _infoRow('VIN', car.vin),
                _infoRow('Госномер', car.plate),
                _infoRow('Пробег', car.mileage),
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
                    '${car.daysInCurrentStatus} дн. (залежалась)',
                  ),
                if (car.saleDate.isNotEmpty)
                  _infoRow(
                    'Дата продажи',
                    formatDate(car.saleDateTime!),
                  ),
              ],
            ),
          ),
          if (car.seller.isNotEmpty ||
              car.sellerPhone.isNotEmpty ||
              car.sellerAddress.isNotEmpty) ...[
            const SectionTitle(
              text: 'Продавец',
              icon: Icons.person_outline,
            ),
            PaddedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (car.seller.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          car.seller,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  if (car.sellerPhone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 16),
                        const SizedBox(width: 8),
                        Text(car.sellerPhone),
                      ],
                    ),
                  ],
                  if (car.sellerAddress.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(car.sellerAddress)),
                      ],
                    ),
                  ],
                  if (car.sellerPhone.isNotEmpty ||
                      car.sellerAddress.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (car.sellerPhone.isNotEmpty)
                          FilledButton.icon(
                            onPressed: _call,
                            icon: const Icon(Icons.phone, size: 18),
                            label: const Text('Позвонить'),
                          ),
                        if (car.sellerAddress.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: _openAddress,
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: const Text('Карта'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SectionTitle(
            text: 'Финансы',
            icon: Icons.account_balance_wallet_outlined,
          ),
          PaddedCard(
            child: Column(
              children: [
                DetailRow(
                    label: 'Цена покупки', value: money(car.purchase)),
                DetailRow(
                    label: 'Расходы', value: money(car.expensesTotal)),
                const Divider(),
                DetailRow(
                  label: 'Всего вложено',
                  value: money(car.invested),
                  bold: true,
                  valueColor: const Color(0xFF4A4FC7),
                ),
                DetailRow(
                  label: 'Безубыточная цена',
                  value: money(car.breakEvenPrice),
                  bold: true,
                  valueColor: const Color(0xFFF59E0B),
                ),
                const Divider(),
                DetailRow(
                    label: 'Цена продажи', value: money(car.sale)),
                DetailRow(
                  label: 'Прибыль',
                  value: money(car.profit),
                  bold: true,
                  valueColor: car.profit >= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
                if (car.partnerAmount > 0) ...[
                  const Divider(),
                  DetailRow(
                    label: 'Доля партнёра',
                    value: money(car.partnerAmount),
                    valueColor: const Color(0xFF9B5DE5),
                  ),
                  DetailRow(
                    label: 'Прибыль партнёра (33%)',
                    value: money(car.partnerProfit),
                    bold: true,
                    valueColor: const Color(0xFF9B5DE5),
                  ),
                  DetailRow(
                    label: 'Прибыль вам (67%)',
                    value: money(car.isSold ? car.myProfit : 0),
                    bold: true,
                    valueColor: const Color(0xFF10B981),
                  ),
                ],
              ],
            ),
          ),
          const SectionTitle(
            text: 'Расходы',
            icon: Icons.receipt_long_outlined,
          ),
          ExpensesBlock(car: car, onChanged: widget.onChanged),
          const SectionTitle(
            text: 'Документы',
            icon: Icons.folder_outlined,
          ),
          DocumentsBlock(car: car, onChanged: widget.onChanged),
          const SectionTitle(
            text: 'Продажа',
            icon: Icons.sell_outlined,
          ),
          PaddedCard(
            child: Column(
              children: [
                TextField(
                  controller: salePrice,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Цена продажи',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: pickSaleDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Дата продажи',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      saleDate == null
                          ? 'Не указана'
                          : formatDate(saleDate!),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: saveSale,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Сохранить продажу'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
          if (car.notes.isNotEmpty) ...[
            const SectionTitle(
              text: 'Примечания',
              icon: Icons.notes_outlined,
            ),
            PaddedCard(
              child: Text(car.notes,
                  style: const TextStyle(height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class PhotosBlock extends StatelessWidget {
  final Car car;
  final VoidCallback onChanged;

  const PhotosBlock({super.key, required this.car, required this.onChanged});

  Future<void> _addPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Из галереи'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Сделать фото'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 12),
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
    car.photos.add('local:$newPath');
    onChanged();
  }

  Future<void> _removePhoto(int index) async {
    final path = car.photos[index];
    if (!isCloudUrl(path)) {
      try {
        final f = File(localPathOf(path));
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    car.photos.removeAt(index);
    onChanged();
  }

  void _openPhoto(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          child: isCloudUrl(path)
              ? Image.network(path)
              : Image.file(File(localPathOf(path))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PaddedCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library_outlined, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Фотографии',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _addPhoto(context),
                icon: const Icon(Icons.add_a_photo_outlined),
              ),
            ],
          ),
          if (car.photos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Фото пока нет',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: car.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final path = car.photos[index];
                  return Stack(
                    children: [
                      InkWell(
                        onTap: () => _openPhoto(context, path),
                        borderRadius: BorderRadius.circular(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 108,
                            height: 108,
                            child: isCloudUrl(path)
                                ? Image.network(
                                    path,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.black12,
                                      child: const Icon(
                                          Icons.broken_image_outlined),
                                    ),
                                  )
                                : (File(localPathOf(path)).existsSync()
                                    ? Image.file(
                                        File(localPathOf(path)),
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: Colors.black12,
                                        child: const Icon(
                                            Icons.broken_image_outlined),
                                      )),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () => _removePhoto(index),
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
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
    );
  }
}

class DocumentsBlock extends StatelessWidget {
  final Car car;
  final VoidCallback onChanged;

  const DocumentsBlock({
    super.key,
    required this.car,
    required this.onChanged,
  });

  IconData _icon(String type) {
    if (type == 'image') return Icons.image_outlined;
    if (type == 'pdf') return Icons.picture_as_pdf_outlined;
    return Icons.description_outlined;
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
        path: 'local:$newPath',
        type: type,
        addedAt: todayIso(),
      ),
    );
    onChanged();
  }

  Future<void> _open(BuildContext context, Attachment a) async {
    final path = a.path;
    if (isCloudUrl(path)) {
      final uri = Uri.parse(path);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
      return;
    }
    final file = File(localPathOf(path));
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
          insetPadding: const EdgeInsets.all(12),
          child: InteractiveViewer(child: Image.file(file)),
        ),
      );
    } else {
      try {
        await OpenFilex.open(file.path);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось открыть: $e')),
        );
      }
    }
  }

  Future<void> _remove(Attachment a) async {
    if (!isCloudUrl(a.path)) {
      try {
        final f = File(localPathOf(a.path));
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    car.attachments.removeWhere((x) => x.id == a.id);
    onChanged();
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Сфотографировать'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, 'camera');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
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
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PaddedCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_outlined, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Документы',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showAddMenu(context),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (car.attachments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Документов пока нет',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...car.attachments.map(
              (a) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _icon(a.type),
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: Text(
                  a.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  a.addedAt,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _remove(a),
                ),
                onTap: () => _open(context, a),
              ),
            ),
        ],
      ),
    );
  }
}
class ExpensesBlock extends StatelessWidget {
  final Car car;
  final VoidCallback onChanged;

  const ExpensesBlock({super.key, required this.car, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PaddedCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Расходы',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => showExpenseDialog(
                  context: context,
                  car: car,
                  onChanged: onChanged,
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (car.expenses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Расходов пока нет',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...car.expenses.map(
              (expense) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                ),
                title: Text(
                  expense.category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  expense.note.isEmpty
                      ? 'Нажмите, чтобы изменить'
                      : expense.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  money(expense.amount),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Сумма',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: note,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Комментарий',
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
                    style: TextStyle(color: Color(0xFFEF4444)),
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
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    for (final path in t.car.photos) {
      if (isCloudUrl(path)) continue;
      try {
        final f = File(localPathOf(path));
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    for (final a in t.car.attachments) {
      if (isCloudUrl(a.path)) continue;
      try {
        final f = File(localPathOf(a.path));
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
              ? const EmptyState(
                  icon: Icons.delete_outline,
                  title: 'Корзина пуста',
                  subtitle: 'Удалённые авто хранятся здесь 30 дней',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: trash.length,
                  itemBuilder: (context, index) {
                    final t = trash[index];
                    final car = t.car;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: PaddedCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${car.make} ${car.model}',
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Удалён: ${t.deletedAt}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _restore(t),
                                    icon: const Icon(
                                        Icons.restore_from_trash_outlined,
                                        size: 18),
                                    label: const Text('Восстановить'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _deleteForever(t),
                                  icon: const Icon(
                                    Icons.delete_forever_outlined,
                                    color: Color(0xFFEF4444),
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
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool isLogin = true;
  bool loading = false;
  bool showPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Введите email и пароль');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showMessage('Некорректный email');
      return;
    }
    if (password.length < 6) {
      _showMessage('Пароль должен быть не менее 6 символов');
      return;
    }
    if (!isLogin && password != confirmController.text) {
      _showMessage('Пароли не совпадают');
      return;
    }

    setState(() => loading = true);
    try {
      if (isLogin) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (!mounted) return;
        _showMessage('Вы вошли');
      } else {
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        if (!mounted) return;
        _showMessage(
          'Проверьте почту $email — там письмо для подтверждения',
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMessage(_russianError(e.message));
    } catch (e) {
      if (!mounted) return;
      _showMessage('Ошибка: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _russianError(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('invalid login')) return 'Неверный email или пароль';
    if (m.contains('email not confirmed')) {
      return 'Email не подтверждён. Проверьте почту';
    }
    if (m.contains('user already registered')) {
      return 'Такой email уже зарегистрирован';
    }
    if (m.contains('password')) return 'Пароль слишком простой';
    if (m.contains('rate limit')) {
      return 'Слишком много попыток. Подождите минуту';
    }
    if (m.contains('network')) return 'Нет соединения с интернетом';
    return msg;
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Сначала введите email');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      _showMessage('Письмо для сброса пароля отправлено на $email');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Ошибка: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1B2E),
                    const Color(0xFF14151A),
                  ]
                : [
                    kSeedColor.withValues(alpha: 0.16),
                    const Color(0xFFF6F7FB),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF4A4FC7),
                            Color(0xFF6D72E0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: kSeedColor.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Авто Профит',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isLogin
                          ? 'Войдите в аккаунт'
                          : 'Создайте новый аккаунт',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.06,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: passwordController,
                            obscureText: !showPassword,
                            textInputAction: isLogin
                                ? TextInputAction.done
                                : TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Пароль',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () => setState(
                                  () => showPassword = !showPassword,
                                ),
                              ),
                            ),
                          ),
                          if (!isLogin) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: confirmController,
                              obscureText: !showPassword,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Повторите пароль',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: loading ? null : _submit,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isLogin
                                        ? 'Войти'
                                        : 'Зарегистрироваться',
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => setState(() {
                                isLogin = !isLogin;
                                passwordController.clear();
                                confirmController.clear();
                              }),
                      child: Text(
                        isLogin
                            ? 'Нет аккаунта? Зарегистрироваться'
                            : 'Уже есть аккаунт? Войти',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isLogin)
                      TextButton(
                        onPressed: loading ? null : _resetPassword,
                        child: const Text('Забыли пароль?'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class ContractDialog extends StatefulWidget {
  final Car car;
  const ContractDialog({super.key, required this.car});

  @override
  State<ContractDialog> createState() => _ContractDialogState();
}

class _ContractDialogState extends State<ContractDialog> {
  final sellerFio = TextEditingController();
  final sellerPassport = TextEditingController();
  final sellerAddress = TextEditingController();
  final sellerPhone = TextEditingController();
  final buyerFio = TextEditingController();
  final buyerPassport = TextEditingController();
  final buyerAddress = TextEditingController();
  final buyerPhone = TextEditingController();
  final priceController = TextEditingController();
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Договор купли-продажи',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.car.make} ${widget.car.model}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 24),
            const Text(
              'Продавец',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _dlgField(sellerFio, 'ФИО'),
            _dlgField(sellerPassport, 'Паспорт'),
            _dlgField(sellerAddress, 'Адрес регистрации'),
            _dlgField(sellerPhone, 'Телефон'),
            const Divider(height: 24),
            const Text(
              'Покупатель',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _dlgField(buyerFio, 'ФИО'),
            _dlgField(buyerPassport, 'Паспорт'),
            _dlgField(buyerAddress, 'Адрес регистрации'),
            _dlgField(buyerPhone, 'Телефон'),
            const Divider(height: 24),
            _dlgField(priceController, 'Цена продажи (₽)', number: true),
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
                    icon: const Icon(Icons.description_outlined, size: 18),
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
  final priceRub =
      NumberFormat('#,##0').format(priceNum).replaceAll(',', ' ');
  final priceWords = _numToRussianWords(priceNum.round());

  String row(String label, String value) =>
      '<tr><td class="lbl">$label</td><td class="val">$value</td></tr>';

  final html = '''
<!DOCTYPE html>
<html lang="ru"><head><meta charset="utf-8">
<title>ДКП ${car.make} ${car.model}</title>
<style>
  *{box-sizing:border-box;}
  body{font-family:'Times New Roman',serif;margin:25px;line-height:1.45;color:#000;font-size:13px;}
  h1{text-align:center;font-size:16px;margin:0 0 4px;letter-spacing:.5px;}
  .sub{text-align:center;font-size:12px;margin-bottom:14px;}
  .place{text-align:right;font-size:12px;margin-bottom:14px;}
  h3{font-size:13px;margin:14px 0 6px;border-bottom:1px solid #000;padding-bottom:3px;}
  p{text-align:justify;font-size:12.5px;margin:5px 0;}
  table{width:100%;border-collapse:collapse;margin:6px 0;}
  td{padding:3px 6px;vertical-align:top;font-size:12.5px;border-bottom:1px dotted #999;}
  .lbl{width:38%;font-weight:bold;}
  .val{width:62%;}
  .sign{display:flex;justify-content:space-between;margin-top:34px;}
  .sign>div{width:46%;}
  .line{border-bottom:1px solid #000;height:22px;margin-bottom:3px;}
  .hint{font-size:11px;color:#555;}
  @media print{body{margin:12mm;} .noprint{display:none;}}
</style></head><body>

<h1>ДОГОВОР КУПЛИ-ПРОДАЖИ ТРАНСПОРТНОГО СРЕДСТВА</h1>
<div class="sub">№ ${car.id} от $day $month $year г.</div>
<div class="place">г. _________________, $day $month $year г.</div>

<p>Гражданин(ка) <b>${seller['fio'] ?? ''}</b>, паспорт ${seller['passport'] ?? ''},
зарегистрированный(ая) по адресу: ${seller['address'] ?? ''},
телефон: ${seller['phone'] ?? ''} — «Продавец», с одной стороны, и</p>

<p>Гражданин(ка) <b>${buyer['fio'] ?? ''}</b>, паспорт ${buyer['passport'] ?? ''},
зарегистрированный(ая) по адресу: ${buyer['address'] ?? ''},
телефон: ${buyer['phone'] ?? ''} — «Покупатель», с другой стороны,
заключили настоящий договор о нижеследующем.</p>

<h3>1. ПРЕДМЕТ ДОГОВОРА</h3>
<p>Продавец передаёт, а Покупатель принимает в собственность транспортное средство:</p>
<table>
${row('Марка, модель ТС', '${car.make} ${car.model}')}
${row('Год выпуска', car.year)}
${row('Идентификационный номер (VIN)', car.vin)}
${row('Государственный регистрационный знак', car.plate)}
${row('Пробег, км', car.mileage.isEmpty ? '—' : car.mileage)}
${row('Техническое состояние', 'удовлетворительное')}
</table>

<h3>2. ЦЕНА И ПОРЯДОК РАСЧЁТОВ</h3>
<p>Стоимость ТС составляет <b>$priceRub ₽</b> ($priceWords).</p>
<p>Денежные средства переданы Продавцу в полном объёме до подписания
настоящего договора. Претензий по расчётам Стороны не имеют.</p>

<h3>3. ПЕРЕДАЧА АВТОМОБИЛЯ</h3>
<p>Продавец передаёт Покупателю автомобиль, ключи, ПТС, СТС и иные
документы, необходимые для регистрации в ГИБДД. Покупатель обязуется
в течение 10 дней со дня подписания договора обратиться в органы
ГИБДД для перерегистрации транспортного средства на своё имя.</p>

<h3>4. ОТВЕТСТВЕННОСТЬ СТОРОН</h3>
<p>Продавец гарантирует, что ТС не находится в залоге, не является
предметом спора третьих лиц, не обременено иными обязательствами, а
также не числится в угоне. Все известные недостатки ТС сообщены
Покупателю до подписания договора.</p>

<h3>5. ПРОЧИЕ УСЛОВИЯ</h3>
<p>Договор вступает в силу с момента подписания. Составлен в трёх
экземплярах: по одному для Продавца и Покупателя, третий — для органов
ГИБДД. Все экземпляры имеют одинаковую юридическую силу.</p>

<div class="sign">
  <div>
    <b>Продавец</b>
    <div class="line"></div>
    <div class="hint">${seller['fio'] ?? ''}</div>
  </div>
  <div>
    <b>Покупатель</b>
    <div class="line"></div>
    <div class="hint">${buyer['fio'] ?? ''}</div>
  </div>
</div>

<p style="margin-top:24px;text-align:center;" class="hint">
Денежные средства в размере $priceRub ₽ получил, транспортное средство передал:
</p>
<div class="sign">
  <div>
    <div class="line"></div>
    <div class="hint">подпись Продавца</div>
  </div>
  <div>
    <div class="line"></div>
    <div class="hint">подпись Покупателя</div>
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
