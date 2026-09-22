import 'constants.dart';
import 'models.dart';

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
