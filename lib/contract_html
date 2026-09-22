import 'dart:io';

import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'car.dart';

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
