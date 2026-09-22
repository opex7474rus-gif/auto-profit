import 'dart:io';

import 'package:flutter/material.dart';

import 'car.dart';
import 'storage.dart';
import 'utils.dart';
import 'widgets_ui.dart';

class TrashScreen extends StatefulWidget {
  final void Function(Car) onRestore;

  const TrashScreen({super.key, required this.onRestore});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<TrashEntry> trash = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await Storage.loadTrash();
    if (!mounted) return;
    setState(() {
      trash = data;
      loading = false;
    });
  }

  Future<void> _restore(TrashEntry t) async {
    trash.removeWhere((x) => x.car.id == t.car.id);
    await Storage.saveTrash(trash);
    widget.onRestore(t.car);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Автомобиль восстановлен')),
    );
  }

  Future<void> _deleteForever(TrashEntry t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить навсегда?'),
        content: const Text(
          'Автомобиль и все связанные файлы будут удалены без возможности восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true) return;
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
    trash.removeWhere((x) => x.car.id == t.car.id);
    await Storage.saveTrash(trash);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Корзина (${trash.length})'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : trash.isEmpty
              ? const EmptyState(
                  icon: Icons.delete_outline,
                  title: 'Корзина пуста',
                  subtitle: 'Удалённые авто хранятся здесь 30 дней',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: trash.length,
                  itemBuilder: (context, index) {
                    final t = trash[index];
                    final car = t.car;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: PaddedCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${car.make} ${car.model}',
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Удалён: ${t.deletedAt}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _restore(t),
                                    icon: const Icon(
                                        Icons.restore_from_trash_outlined,
                                        size: 18),
                                    label: const Text('Восстановить'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _deleteForever(t),
                                  icon: const Icon(
                                    Icons.delete_forever_outlined,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
