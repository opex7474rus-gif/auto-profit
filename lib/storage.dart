import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'car.dart';
import 'constants.dart';
import 'models.dart';
import 'utils.dart';

class Storage {
  static const _key = 'cars_v1';
  static const _trashKey = 'cars_trash_v1';
  static const _themeKey = 'theme_mode_v1';
  static const _sellerKey = 'seller_data_v1';
  static const _buyerKey = 'buyer_data_v1';
  static const _pendingKey = 'pending_sync_v1';

  static SupabaseClient get _db => Supabase.instance.client;
  static String? get _uid => _db.auth.currentUser?.id;

  /// Загрузка файла по локальному пути — только Android/iOS.
  /// На web не используется, там работает [uploadBytes].
  static Future<String?> uploadFile({
    required String bucket,
    required String localPath,
  }) async {
    if (kIsWeb) return null;
    try {
      final uid = _uid;
      if (uid == null) return null;
      final f = File(localPath);
      if (!await f.exists()) return null;
      final ext = p.extension(localPath).toLowerCase();
      final name =
          '$uid/${DateTime.now().microsecondsSinceEpoch}${ext.isEmpty ? '.bin' : ext}';
      await _db.storage.from(bucket).upload(name, f);
      return _db.storage.from(bucket).getPublicUrl(name);
    } catch (_) {
      return null;
    }
  }

  /// Загрузка файла из байтов — работает на всех платформах,
  /// включая Web (там файл — это Uint8List из браузера).
  static Future<String?> uploadBytes({
    required String bucket,
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) return null;
      final ext = p.extension(filename).toLowerCase();
      final name =
          '$uid/${DateTime.now().microsecondsSinceEpoch}${ext.isEmpty ? '.bin' : ext}';
      await _db.storage.from(bucket).uploadBinary(
            name,
            bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
          );
      return _db.storage.from(bucket).getPublicUrl(name);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_pendingKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setPending(bool v) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pendingKey, v);
    } catch (_) {}
  }

  static Map<String, dynamic> _carToRow(Car c) {
    final uid = _uid;
    return {
      if (uid != null) 'user_id': uid,
      'id': c.id,
      'make': c.make,
      'model': c.model,
      'year': c.year,
      'vin': c.vin,
      'plate': c.plate,
      'mileage': c.mileage,
      'purchase_price': c.purchasePrice,
      'purchase_date': c.purchaseDate,
      'status': c.status,
      'status_changed_at': c.statusChangedAt,
      'seller': c.seller,
      'seller_phone': c.sellerPhone,
      'seller_address': c.sellerAddress,
      'notes': c.notes,
      'sale_price': c.salePrice,
      'sale_date': c.saleDate,
      'partner_investment': c.partnerInvestment,
      'tags': c.tags,
      'expenses': c.expenses.map((e) => e.toJson()).toList(),
      'photos': c.photos,
      'attachments': c.attachments.map((a) => a.toJson()).toList(),
    };
  }

  static Car _rowToCar(Map<String, dynamic> r) {
    return Car(
      id: (r['id'] ?? '') as String,
      make: (r['make'] ?? '') as String,
      model: (r['model'] ?? '') as String,
      year: (r['year'] ?? '') as String,
      vin: (r['vin'] ?? '') as String,
      plate: (r['plate'] ?? '') as String,
      mileage: (r['mileage'] ?? '') as String,
      purchasePrice: (r['purchase_price'] ?? '') as String,
      purchaseDate: (r['purchase_date'] ?? '') as String,
      status: (r['status'] ?? 'Куплен') as String,
      statusChangedAt: (r['status_changed_at'] ?? '') as String,
      seller: (r['seller'] ?? '') as String,
      sellerPhone: (r['seller_phone'] ?? '') as String,
      sellerAddress: (r['seller_address'] ?? '') as String,
      notes: (r['notes'] ?? '') as String,
      salePrice: (r['sale_price'] ?? '') as String,
      saleDate: (r['sale_date'] ?? '') as String,
      partnerInvestment: (r['partner_investment'] ?? '') as String,
      tags: ((r['tags'] ?? []) as List)
          .map((e) => e.toString())
          .toList(),
      expenses: ((r['expenses'] ?? []) as List)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList(),
      photos: ((r['photos'] ?? []) as List)
          .map((e) => e.toString())
          .toList(),
      attachments: ((r['attachments'] ?? []) as List)
          .map((e) => Attachment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
    static Future<List<Car>> load() async {
    List<Car> local = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        local = list
            .map((e) => Car.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    try {
      if (_uid != null) {
        final rows = await _db
            .from('cars')
            .select()
            .order('created_at', ascending: true);
        final cars = (rows as List)
            .map((r) => _rowToCar(r as Map<String, dynamic>))
            .toList();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _key,
          jsonEncode(cars.map((c) => c.toJson()).toList()),
        );

        if (await hasPending()) {
          await save(cars);
        }

        return cars;
      }
    } catch (_) {}

    return local;
  }

  static Future<void> save(List<Car> cars) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(cars.map((c) => c.toJson()).toList()),
      );
    } catch (_) {}

    try {
      if (_uid == null) return;

      bool allUploaded = true;

      if (!kIsWeb) {
        for (final c in cars) {
          final newPhotos = <String>[];
          for (final ph in c.photos) {
            if (isLocalMarker(ph)) {
              final url = await uploadFile(
                bucket: 'photos',
                localPath: localPathOf(ph),
              );
              if (url != null) {
                newPhotos.add(url);
              } else {
                newPhotos.add(ph);
                allUploaded = false;
              }
            } else {
              newPhotos.add(ph);
            }
          }
          c.photos = newPhotos;

          for (final a in c.attachments) {
            if (isLocalMarker(a.path)) {
              final url = await uploadFile(
                bucket: 'documents',
                localPath: localPathOf(a.path),
              );
              if (url != null) {
                a.path = url;
              } else {
                allUploaded = false;
              }
            }
          }
        }
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _key,
          jsonEncode(cars.map((c) => c.toJson()).toList()),
        );
      } catch (_) {}

      final existingRows = await _db.from('cars').select('id');
      final existingIds = (existingRows as List)
          .map((r) => (r['id'] ?? '').toString())
          .toSet();

      if (cars.isNotEmpty) {
        final rows = cars.map((c) => _carToRow(c)).toList();
        await _db.from('cars').upsert(rows);
      }

      final localIds = cars.map((c) => c.id).toSet();
      final toDelete = existingIds.difference(localIds).toList();
      if (toDelete.isNotEmpty) {
        await _db.from('cars').delete().inFilter('id', toDelete);
      }

      await setPending(!allUploaded);
    } catch (_) {
      await setPending(true);
    }
  }

  static Future<void> clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      await prefs.remove(_trashKey);
      await prefs.remove(_pendingKey);
    } catch (_) {}
  }

  static Future<List<TrashEntry>> loadTrash() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_trashKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => TrashEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTrash(List<TrashEntry> trash) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _trashKey,
      jsonEncode(trash.map((t) => t.toJson()).toList()),
    );
  }

  static Future<void> cleanupTrash() async {
    if (kIsWeb) return;
    final trash = await loadTrash();
    final now = DateTime.now();
    final cleaned = <TrashEntry>[];
    for (final t in trash) {
      final d = DateTime.tryParse(t.deletedAt);
      if (d == null) continue;
      if (now.difference(d).inDays < kTrashDays) {
        cleaned.add(t);
      } else {
        for (final path in t.car.photos) {
          if (isCloudUrl(path)) continue;
          try {
            final f = File(localPathOf(path));
            if (await f.exists()) await f.delete();
          } catch (_) {}
        }
        for (final a in t.car.attachments) {
          if (isCloudUrl(a.path)) continue;
          try {
            final f = File(localPathOf(a.path));
            if (await f.exists()) await f.delete();
          } catch (_) {}
        }
      }
    }
    await saveTrash(cleaned);
  }

  static Future<ThemeMode> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeKey);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await prefs.setString(_themeKey, raw);
  }

  static Future<Map<String, String>> loadPartyData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return Map.from(kDefaultBuyerData);
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return Map.from(kDefaultBuyerData);
    }
  }

  static Future<void> savePartyData(
    String key,
    Map<String, String> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }

  static Future<Map<String, String>> loadSellerData() =>
      loadPartyData(_sellerKey);

  static Future<void> saveSellerData(Map<String, String> data) =>
      savePartyData(_sellerKey, data);

  static Future<Map<String, String>> loadBuyerData() =>
      loadPartyData(_buyerKey);

  static Future<void> saveBuyerData(Map<String, String> data) =>
      savePartyData(_buyerKey, data);
}
