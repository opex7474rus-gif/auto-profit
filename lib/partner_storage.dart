import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'partner.dart';

class PartnerStorage {
  static const _settingsKey = 'partner_settings_v1';
  static const _txKey = 'partner_transactions_v1';

  static SupabaseClient get _db => Supabase.instance.client;
  static String? get _uid => _db.auth.currentUser?.id;

  // === НАСТРОЙКИ ===

  static Future<PartnerSettings> loadSettings() async {
    // Сначала пробуем облако
    try {
      if (_uid != null) {
        final rows = await _db
            .from('partner_settings')
            .select()
            .eq('user_id', _uid!)
            .limit(1);
        if (rows.isNotEmpty) {
          final s = PartnerSettings.fromJson(
            rows.first as Map<String, dynamic>,
          );
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_settingsKey, jsonEncode(s.toJson()));
          return s;
        }
      }
    } catch (_) {}

    // Fallback — локально
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_settingsKey);
      if (raw != null && raw.isNotEmpty) {
        return PartnerSettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
    } catch (_) {}

    return PartnerSettings();
  }

  static Future<void> saveSettings(PartnerSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _settingsKey,
        jsonEncode(settings.toJson()),
      );
    } catch (_) {}

    try {
      if (_uid == null) return;
      final row = {
        'user_id': _uid,
        'name': settings.name,
        'phone': settings.phone,
        'notes': settings.notes,
      };
      await _db.from('partner_settings').upsert(
            row,
            onConflict: 'user_id',
          );
    } catch (_) {}
  }

  // === ОПЕРАЦИИ ===

  static Future<List<PartnerTransaction>> loadTransactions() async {
    List<PartnerTransaction> local = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_txKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        local = list
            .map((e) =>
                PartnerTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    try {
      if (_uid != null) {
        final rows = await _db
            .from('partner_transactions')
            .select()
            .order('date', ascending: false);
        final tx = (rows as List)
            .map((e) =>
                PartnerTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _txKey,
          jsonEncode(tx.map((t) => t.toJson()).toList()),
        );
        return tx;
      }
    } catch (_) {}

    return local;
  }

  static Future<void> saveTransaction(PartnerTransaction tx) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_txKey);
      List<PartnerTransaction> list = [];
      if (raw != null && raw.isNotEmpty) {
        list = (jsonDecode(raw) as List)
            .map((e) =>
                PartnerTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      list.insert(0, tx);
      await prefs.setString(
        _txKey,
        jsonEncode(list.map((t) => t.toJson()).toList()),
      );
    } catch (_) {}

    try {
      if (_uid == null) return;
      await _db.from('partner_transactions').upsert({
        'id': tx.id,
        'user_id': _uid,
        'type': tx.type,
        'amount': tx.amount,
        'note': tx.note,
        'date': tx.date,
      });
    } catch (_) {}
  }

  static Future<void> deleteTransaction(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_txKey);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List)
            .map((e) =>
                PartnerTransaction.fromJson(e as Map<String, dynamic>))
            .where((t) => t.id != id)
            .toList();
        await prefs.setString(
          _txKey,
          jsonEncode(list.map((t) => t.toJson()).toList()),
        );
      }
    } catch (_) {}

    try {
      if (_uid == null) return;
      await _db.from('partner_transactions').delete().eq('id', id);
    } catch (_) {}
  }

  static Future<void> clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_settingsKey);
      await prefs.remove(_txKey);
    } catch (_) {}
  }
}
