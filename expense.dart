class Expense {
  final int? id;
  final int carId;
  final int categoryId;
  final double amount;
  final DateTime date;
  final String note;
  const Expense({this.id, required this.carId, required this.categoryId, required this.amount, required this.date, this.note = ''});
  Map<String, Object?> toMap() => {'id': id, 'car_id': carId, 'category_id': categoryId, 'amount': amount, 'date': date.toIso8601String(), 'note': note};
  factory Expense.fromMap(Map<String, Object?> m) => Expense(id: m['id'] as int?, carId: m['car_id'] as int, categoryId: m['category_id'] as int, amount: (m['amount'] as num).toDouble(), date: DateTime.parse(m['date'] as String), note: (m['note'] as String?) ?? '');
}
