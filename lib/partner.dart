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
///
/// Модель «общак»: все деньги партнёра делятся на
/// свободные (можно забрать) и замороженные (в машинах).
class PartnerBalance {
  /// Σ его долей по всем машинам.
  final double investedInCars;

  /// Σ его долей по машинам в наличии (заморожено).
  final double inWorkNow;

  /// Σ его долей по проданным (вернулось в общак).
  final double returned;

  /// Σ его прибыли по проданным (лежит в общаке).
  final double profitShare;

  /// Σ операций «Внёс» (руками).
  final double manualIn;

  /// Σ операций «Забрал» (руками).
  final double manualOut;

  const PartnerBalance({
    required this.investedInCars,
    required this.inWorkNow,
    required this.returned,
    required this.profitShare,
    required this.manualIn,
    required this.manualOut,
  });

  /// Свободные деньги партнёра в общаке — можно забрать.
  double get freeInPot =>
      returned + profitShare + manualIn - manualOut;

  /// Заморожено в машинах на складе.
  double get frozenInCars => inWorkNow;

  /// Всего денег партнёра в бизнесе.
  double get totalInBusiness => freeInPot + frozenInCars;

  /// Если он забрал больше, чем имел — сколько остался должен.
  double get overspent => freeInPot < 0 ? -freeInPot : 0;
}
