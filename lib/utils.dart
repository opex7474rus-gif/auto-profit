import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'car.dart';

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

bool isCloudUrl(String s) => s.startsWith('http');

bool isLocalMarker(String s) => s.startsWith('local:');

String localPathOf(String s) {
  if (isLocalMarker(s)) return s.substring(6);
  return s;
}

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
