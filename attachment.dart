class Attachment {
  final int? id;
  final int carId;
  final int? expenseId;
  final String path;
  final String name;
  final String type;
  const Attachment({this.id, required this.carId, this.expenseId, required this.path, required this.name, required this.type});
  Map<String, Object?> toMap() => {'id': id, 'car_id': carId, 'expense_id': expenseId, 'path': path, 'name': name, 'type': type};
  factory Attachment.fromMap(Map<String, Object?> m) => Attachment(id: m['id'] as int?, carId: m['car_id'] as int, expenseId: m['expense_id'] as int?, path: m['path'] as String, name: m['name'] as String, type: m['type'] as String);
}
