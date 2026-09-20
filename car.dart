class Car {
  final int? id;
  final String make;
  final String model;
  final int? year;
  final String vin;
  final String plate;
  final int? mileage;
  final DateTime purchaseDate;
  final double purchasePrice;
  final String seller;
  final String notes;
  final String status;
  final DateTime? saleDate;
  final double? salePrice;

  const Car({this.id, required this.make, required this.model, this.year, this.vin = '', this.plate = '', this.mileage, required this.purchaseDate, required this.purchasePrice, this.seller = '', this.notes = '', this.status = 'Куплен', this.saleDate, this.salePrice});

  double get sale => salePrice ?? 0;

  Car copyWith({int? id, String? make, String? model, int? year, String? vin, String? plate, int? mileage, DateTime? purchaseDate, double? purchasePrice, String? seller, String? notes, String? status, DateTime? saleDate, double? salePrice}) => Car(
    id: id ?? this.id, make: make ?? this.make, model: model ?? this.model, year: year ?? this.year, vin: vin ?? this.vin, plate: plate ?? this.plate, mileage: mileage ?? this.mileage,
    purchaseDate: purchaseDate ?? this.purchaseDate, purchasePrice: purchasePrice ?? this.purchasePrice, seller: seller ?? this.seller, notes: notes ?? this.notes,
    status: status ?? this.status, saleDate: saleDate ?? this.saleDate, salePrice: salePrice ?? this.salePrice,
  );

  Map<String, Object?> toMap() => {'id': id, 'make': make, 'model': model, 'year': year, 'vin': vin, 'plate': plate, 'mileage': mileage, 'purchase_date': purchaseDate.toIso8601String(), 'purchase_price': purchasePrice, 'seller': seller, 'notes': notes, 'status': status, 'sale_date': saleDate?.toIso8601String(), 'sale_price': salePrice};
  factory Car.fromMap(Map<String, Object?> m) => Car(id: m['id'] as int?, make: m['make'] as String, model: m['model'] as String, year: m['year'] as int?, vin: (m['vin'] as String?) ?? '', plate: (m['plate'] as String?) ?? '', mileage: m['mileage'] as int?, purchaseDate: DateTime.parse(m['purchase_date'] as String), purchasePrice: (m['purchase_price'] as num).toDouble(), seller: (m['seller'] as String?) ?? '', notes: (m['notes'] as String?) ?? '', status: (m['status'] as String?) ?? 'Куплен', saleDate: m['sale_date'] == null ? null : DateTime.parse(m['sale_date'] as String), salePrice: m['sale_price'] == null ? null : (m['sale_price'] as num).toDouble());
}
