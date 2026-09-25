import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'service.dart';

class ServiceStorage {
  static const _key = 'services_v1';

  static SupabaseClient get _db => Supabase.instance.client;
  static String? get _uid => _db.auth.currentUser?.id;

  static Future<List<Service>> load() async {
    List<Service> local = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        local = list
            .map((e) => Service.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    try {
      if (_uid != null) {
        final rows = await _db
            .from('services')
            .select()
            .order('created_at', ascending: true);
        final services = (rows as List)
            .map((e) => Service.fromJson(e as Map<String, dynamic>))
            .toList();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _key,
          jsonEncode(services.map((s) => s.toJson()).toList()),
        );
        return services;
      }
    } catch (_) {}

    return local;
  }

  static Future<void> save(List<Service> services) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(services.map((s) => s.toJson()).toList()),
      );
    } catch (_) {}

    try {
      if (_uid == null) return;

      final existing = await _db.from('services').select('id');
      final existingIds = (existing as List)
          .map((r) => (r['id'] ?? '').toString())
          .toSet();

      if (services.isNotEmpty) {
        final rows = services
            .map((s) => {
                  'id': s.id,
                  'user_id': _uid,
                  'name': s.name,
                  'type': s.type,
                  'contact_name': s.contactName,
                  'phone': s.phone,
                  'address': s.address,
                  'notes': s.notes,
                  'favorite': s.favorite,
                })
            .toList();
        await _db.from('services').upsert(rows);
      }

      final localIds = services.map((s) => s.id).toSet();
      final toDelete = existingIds.difference(localIds).toList();
      if (toDelete.isNotEmpty) {
        await _db.from('services').delete().inFilter('id', toDelete);
      }
    } catch (_) {}
  }

  static Future<void> clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
