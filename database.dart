import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();
  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final p = join(await getDatabasesPath(), 'auto_profit.db');
    _db = await openDatabase(p, version: 1, onConfigure: (d) async => d.execute('PRAGMA foreign_keys = ON'), onCreate: (d, v) async {
      await d.execute('CREATE TABLE cars(id INTEGER PRIMARY KEY AUTOINCREMENT, make TEXT NOT NULL, model TEXT NOT NULL, year INTEGER, vin TEXT, plate TEXT, mileage INTEGER, purchase_date TEXT NOT NULL, purchase_price REAL NOT NULL, seller TEXT, notes TEXT, status TEXT NOT NULL, sale_date TEXT, sale_price REAL)');
      await d.execute('CREATE TABLE expense_categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)');
      await d.execute('CREATE TABLE expenses(id INTEGER PRIMARY KEY AUTOINCREMENT, car_id INTEGER NOT NULL, category_id INTEGER NOT NULL, amount REAL NOT NULL, date TEXT NOT NULL, note TEXT, FOREIGN KEY(car_id) REFERENCES cars(id) ON DELETE CASCADE, FOREIGN KEY(category_id) REFERENCES expense_categories(id) ON DELETE RESTRICT)');
      await d.execute('CREATE TABLE attachments(id INTEGER PRIMARY KEY AUTOINCREMENT, car_id INTEGER NOT NULL, expense_id INTEGER, path TEXT NOT NULL, name TEXT NOT NULL, type TEXT NOT NULL, FOREIGN KEY(car_id) REFERENCES cars(id) ON DELETE CASCADE, FOREIGN KEY(expense_id) REFERENCES expenses(id) ON DELETE CASCADE)');
      for (final n in ['Ремонт','Запчасти','Шиномонтаж','Резина','Мойка','Химчистка','Детейлинг','Доставка','Диагностика','Комиссия','Прочее']) { await d.insert('expense_categories', {'name': n}); }
    });
    return _db!;
  }
}
