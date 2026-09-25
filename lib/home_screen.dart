import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'analytics.dart';
import 'analytics_section.dart';
import 'car.dart';
import 'car_details_screen.dart';
import 'car_form_screen.dart';
import 'car_list_tile.dart';
import 'constants.dart';
import 'expenses_block.dart';
import 'history_screen.dart';
import 'partner_screen.dart';
import 'services_screen.dart';
import 'storage.dart';
import 'trash_screen.dart';
import 'utils.dart';
import 'widgets_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Car> cars = [];
  bool loading = true;
  final searchController = TextEditingController();
  String search = '';
  String listMode = 'stock';
  String sortMode = 'purchaseDesc';
  bool showCheckReminder = false;
  int trashCount = 0;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    searchController.dispose();
    super.dispose();
  }

  void _subscribeRealtime() {
    try {
      _channel = Supabase.instance.client
          .channel('cars_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'cars',
            callback: (payload) async {
              final data = await Storage.load();
              if (!mounted) return;
              setState(() {
                cars
                  ..clear()
                  ..addAll(data);
              });
            },
          )
          .subscribe();
    } catch (_) {}
  }

  Future<void> _load() async {
    final data = await Storage.load();
    final trash = await Storage.loadTrash();
    if (!mounted) return;
    setState(() {
      cars
        ..clear()
        ..addAll(data);
      trashCount = trash.length;
      loading = false;
    });
    _checkReminder();
  }

  Future<void> _checkReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString(kLastCheckKey);
    if (lastStr == null) {
      await prefs.setString(kLastCheckKey, todayIso());
      return;
    }
    final last = DateTime.tryParse(lastStr);
    if (last == null) return;
    final diff = DateTime.now().difference(last).inDays;
    if (!mounted) return;
    setState(() => showCheckReminder = diff >= kReminderDays);
  }

  Future<void> _dismissReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kLastCheckKey, todayIso());
    setState(() => showCheckReminder = false);
  }

  Future<void> _persist() async => Storage.save(cars);

  Analytics get analytics => Analytics(cars);

  List<Car> _filter(List<Car> src) {
    final q = search.trim().toLowerCase();
    if (q.isEmpty) return src;
    return src.where((c) {
      return c.make.toLowerCase().contains(q) ||
          c.model.toLowerCase().contains(q) ||
          c.vin.toLowerCase().contains(q) ||
          c.plate.toLowerCase().contains(q) ||
          c.seller.toLowerCase().contains(q) ||
          c.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  List<Car> _sort(List<Car> src) {
    final list = List<Car>.from(src);
    switch (sortMode) {
      case 'purchaseAsc':
        list.sort((a, b) {
          final da = a.purchaseDateTime ?? DateTime(2100);
          final db = b.purchaseDateTime ?? DateTime(2100);
          return da.compareTo(db);
        });
        break;
      case 'profitDesc':
        list.sort((a, b) => b.profit.compareTo(a.profit));
        break;
      case 'alpha':
        list.sort((a, b) => '${a.make} ${a.model}'
            .toLowerCase()
            .compareTo('${b.make} ${b.model}'.toLowerCase()));
        break;
      case 'daysDesc':
        list.sort((a, b) => b.daysInStock.compareTo(a.daysInStock));
        break;
      case 'purchaseDesc':
      default:
        list.sort((a, b) {
          final da = a.purchaseDateTime ?? DateTime(1900);
          final db = b.purchaseDateTime ?? DateTime(1900);
          return db.compareTo(da);
        });
    }
    return list;
  }

  void addCar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarFormScreen(
          onSave: (car) {
            setState(() => cars.add(car));
            _persist();
          },
        ),
      ),
    );
  }

  void openCar(Car car) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarDetailsScreen(
          car: car,
          onChanged: () {
            if (!mounted) return;
            setState(() {});
            _persist();
          },
          onDelete: () async {
            final trash = await Storage.loadTrash();
            trash.add(
              TrashEntry(car: car, deletedAt: todayIso()),
            );
            await Storage.saveTrash(trash);
            if (!mounted) return;
            setState(() {
              cars.removeWhere((c) => c.id == car.id);
              trashCount = trash.length;
            });
            _persist();
          },
          onDuplicate: (newCar) {
            setState(() => cars.add(newCar));
            _persist();
          },
        ),
      ),
    );
  }

  void openTrash() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrashScreen(
          onRestore: (car) {
            setState(() => cars.add(car));
            _persist();
            _load();
          },
        ),
      ),
    );
    _load();
  }

  void openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryScreen(cars: cars),
      ),
    );
  }

  void openPartner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartnerScreen(cars: cars),
      ),
    );
  }

  void openServices() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ServicesScreen(),
      ),
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text(
          'Данные останутся в облаке и будут доступны при следующем входе.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await Storage.clearLocalCache();
      await Supabase.instance.client.auth.signOut();
    }
  }

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      default:
        return Icons.brightness_auto_outlined;
    }
  }

  void _cycleTheme(ThemeMode mode) {
    final next = mode == ThemeMode.system
        ? ThemeMode.light
        : mode == ThemeMode.light
            ? ThemeMode.dark
            : ThemeMode.system;
    themeNotifier.value = next;
    Storage.saveTheme(next);
  }

  Future<void> exportJson() async {
    try {
      final data = jsonEncode(cars.map((c) => c.toJson()).toList());
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/auto_profit_backup.json');
      await file.writeAsString(data);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Резервная копия Авто Профит',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка экспорта: $e')),
      );
    }
  }

  Future<void> importJson() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null) return;
      final path = result.files.single.path;
      if (path == null) return;
      final content = await File(path).readAsString();
      final list = jsonDecode(content) as List;
      final imported = list
          .map((e) => Car.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() => cars.addAll(imported));
      _persist();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Импортировано ${imported.length} авто')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка импорта: $e')),
      );
    }
  }
  @override
Widget build(BuildContext context) {
  if (loading) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  final theme = Theme.of(context);
  final a = analytics;
  final sourceList = listMode == 'stock' ? a.stockCars : a.soldCars;
  final visible = _sort(_filter(sourceList));
  final userEmail =
      Supabase.instance.client.auth.currentUser?.email ?? '';

  return Scaffold(
    appBar: AppBar(
      title: const Text('Авто Профит'),
      actions: [
        PopupMenuButton<String>(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onSelected: (value) {
            if (value == 'partner') openPartner();
            if (value == 'services') openServices();
            if (value == 'history') openHistory();
            if (value == 'export') exportJson();
            if (value == 'csv') exportCsv(cars);
            if (value == 'import') importJson();
            if (value == 'trash') openTrash();
            if (value == 'logout') _logout();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'account',
              enabled: false,
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(
                  userEmail.isEmpty ? 'Аккаунт' : userEmail,
                  style: const TextStyle(fontSize: 12.5),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'partner',
              child: ListTile(
                leading: Icon(Icons.handshake_outlined),
                title: Text('Партнёр'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'services',
              child: ListTile(
                leading: Icon(Icons.contacts_outlined),
                title: Text('Сервис-контакты'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'history',
              child: ListTile(
                leading: Icon(Icons.history),
                title: Text('История покупок/продаж'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.upload_file_outlined),
                title: Text('Экспорт JSON'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'csv',
              child: ListTile(
                leading: Icon(Icons.table_chart_outlined),
                title: Text('Экспорт CSV (Excel)'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'import',
              child: ListTile(
                leading: Icon(Icons.download_outlined),
                title: Text('Импорт JSON'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'trash',
              child: ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text('Корзина ($trashCount)'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('Выйти из аккаунта'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, mode, _) => IconButton(
            tooltip: 'Тема',
            onPressed: () => _cycleTheme(mode),
            icon: Icon(_themeIcon(mode)),
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: addCar,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Добавить'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    body: CustomScrollView(
      slivers: [
        if (showCheckReminder)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.18),
                    const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF59E0B)
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Прошло $kReminderDays дня. Проверьте машины на складе.',
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
                  TextButton(
                    onPressed: _dismissReminder,
                    child: const Text('Ок'),
                  ),
                ],
              ),
            ),
          ),
        if (a.staleCars.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEF4444).withValues(alpha: 0.16),
                    const Color(0xFFEF4444).withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFEF4444)
                      .withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${a.staleCars.length} машин(ы) без изменения статуса больше $kStaleDays дней',
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  text: 'Аналитика',
                  icon: Icons.insights_outlined,
                ),
                AnalyticsSection(analytics: a),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
          sliver: SliverToBoxAdapter(
            child: StatusesCard(counts: a.statusCounts),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          sliver: SliverToBoxAdapter(
            child: TextField(
              controller: searchController,
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(
                hintText: 'Поиск: марка, VIN, госномер, тег…',
                prefixIcon: const Icon(Icons.search_rounded, size: 22),
                suffixIcon: search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          searchController.clear();
                          setState(() => search = '');
                        },
                      ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
          sliver: SliverToBoxAdapter(
            child: _modeTabs(a),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 6, 14, 4),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Icon(
                  listMode == 'stock'
                      ? Icons.warehouse_outlined
                      : Icons.inventory_2_outlined,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    listMode == 'stock'
                        ? 'В наличии · ${visible.length}'
                        : 'Проданные · ${visible.length}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort_rounded),
                  tooltip: 'Сортировка',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (v) => setState(() => sortMode = v),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'purchaseDesc',
                      child: Text('По дате покупки ↓'),
                    ),
                    PopupMenuItem(
                      value: 'purchaseAsc',
                      child: Text('По дате покупки ↑'),
                    ),
                    PopupMenuItem(
                      value: 'profitDesc',
                      child: Text('По прибыли'),
                    ),
                    PopupMenuItem(
                      value: 'daysDesc',
                      child: Text('По дням на складе'),
                    ),
                    PopupMenuItem(
                      value: 'alpha',
                      child: Text('По алфавиту'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (visible.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: listMode == 'stock'
                  ? Icons.directions_car_outlined
                  : Icons.check_circle_outline,
              title: search.isNotEmpty
                  ? 'Ничего не найдено'
                  : listMode == 'stock'
                      ? 'Нет машин в наличии'
                      : 'Нет проданных машин',
              subtitle: listMode == 'stock'
                  ? 'Нажмите «Добавить», чтобы создать первую карточку'
                  : null,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
            sliver: SliverList.builder(
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final car = visible[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: CarListTile(
                    car: car,
                    onTap: () => openCar(car),
                    onQuickExpense: () async {
                      await showExpenseDialogWrapper(
                        context: context,
                        car: car,
                        onChanged: () {
                          setState(() {});
                          _persist();
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
      ],
    ),
  );
}
    Widget _modeTabs(Analytics a) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: ModeTab(
              label: 'В наличии',
              count: a.stockCars.length,
              selected: listMode == 'stock',
              onTap: () => setState(() => listMode = 'stock'),
            ),
          ),
          Expanded(
            child: ModeTab(
              label: 'Проданные',
              count: a.soldCars.length,
              selected: listMode == 'sold',
              onTap: () => setState(() => listMode = 'sold'),
            ),
          ),
        ],
      ),
    );
  }
}
