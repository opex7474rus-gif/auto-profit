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
