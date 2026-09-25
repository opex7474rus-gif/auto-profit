import 'constants.dart';

class Service {
  String id;
  String name;
  String type;
  String contactName;
  String phone;
  String address;
  String notes;
  bool favorite;

  Service({
    required this.id,
    required this.name,
    this.type = '',
    this.contactName = '',
    this.phone = '',
    this.address = '',
    this.notes = '',
    this.favorite = false,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      type: (json['type'] ?? '') as String,
      contactName: (json['contactName'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      notes: (json['notes'] ?? '') as String,
      favorite: (json['favorite'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'contactName': contactName,
        'phone': phone,
        'address': address,
        'notes': notes,
        'favorite': favorite,
      };

  Service copyWith({
    String? name,
    String? type,
    String? contactName,
    String? phone,
    String? address,
    String? notes,
    bool? favorite,
  }) {
    return Service(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      favorite: favorite ?? this.favorite,
    );
  }
}

/// Цвет для бейджа типа — стабильно от строки.
Color serviceTypeColor(String type) {
  if (type.trim().isEmpty) return const Color(0xFF94A3B8);
  const palette = [
    Color(0xFF4A4FC7),
    Color(0xFF10B981),
    Color(0xFFEF4444),
    Color(0xFFFF7A45),
    Color(0xFF9B5DE5),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
  ];
  var hash = 0;
  for (final code in type.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return palette[hash % palette.length];
}
