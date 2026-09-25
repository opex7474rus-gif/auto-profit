import 'constants.dart';

/// Одна операция по партнёрскому счёту.
/// type = 'in' — партнёр внёс деньги
/// type = 'out' — партнёр забрал деньги
class PartnerTransaction {
  String id;
  String type; // 'in' | 'out'
  double amount;
  String note;
  String date;

  PartnerTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.note,
    required this.date,
  });

  factory PartnerTransaction.fromJson(Map<String, dynamic> json) {
    return PartnerTransaction(
      id: (json['id'] ?? '') as String,
      type: (json['type'] ?? 'in') as String,
      amount: ((json['amount'] ?? 0) as num).toDouble(),
      note: (json['note'] ?? '') as String,
      date: (json['date'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'note': note,
        'date': date,
      };

  bool get isIn => type == 'in';
}

/// Настройки партнёра (одна запись на пользователя).
class PartnerSettings {
  String name;
  String phone;
  String notes;

  PartnerSettings({
    this.name = '',
    this.phone = '',
    this.notes = '',
  });

  factory PartnerSettings.fromJson(Map<String, dynamic> json) {
    return PartnerSettings(
      name: (json['name'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      notes: (json['notes'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'notes': notes,
      };
}

/// Итоговый расчёт по партнёру.
class PartnerBalance {
  /// Сколько партнёр вложил в конкретные машины (сумма долей).
  final double investedInCars;

  /// Сколько его денег сейчас в машинах в наличии.
  final double inWorkNow;

  /// Сколько его денег вернулось (по проданным машинам).
  final double returned;

  /// Сколько прибыли ему причитается (по проданным машинам).
  final double profitShare;

  /// Сколько он внёс вручную (операции «in»).
  final double manualIn;

  /// Сколько он забрал вручную (операции «out»).
  final double manualOut;

  const PartnerBalance({
    required this.investedInCars,
    required this.inWorkNow,
    required this.returned,
    required this.profitShare,
    required this.manualIn,
    required this.manualOut,
  });

  /// Всего он внёс (в машины + вручную).
  double get totalIn => investedInCars + manualIn;

  /// Всего он забрал (возврат + вручную).
  double get totalOut => returned + manualOut;

  /// Сколько у него денег в обороте сейчас.
  double get availableInWork => inWorkNow;

  /// Итоговый баланс: положительный — мы должны ему,
  /// отрицательный — он должен нам.
  double get balance => totalIn - totalOut - inWorkNow + profitShare;

  /// Свободный остаток партнёра (то, что он может забрать).
  /// Это деньги, вернувшиеся из сделок + прибыль − то, что уже забрал.
  double get freeBalance => returned + profitShare - manualOut;
}
