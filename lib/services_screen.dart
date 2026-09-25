import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'service.dart';
import 'service_form_screen.dart';
import 'service_storage.dart';
import 'widgets_ui.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final List<Service> services = [];
  bool loading = true;
  String search = '';
  String filterType = '';
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await ServiceStorage.load();
    if (!mounted) return;
    setState(() {
      services
        ..clear()
        ..addAll(data);
      loading = false;
    });
  }

  Future<void> _persist() async {
    await ServiceStorage.save(services);
  }

  List<Service> _filtered() {
    var list = services.toList();

    if (filterType.isNotEmpty) {
      list = list.where((s) => s.type == filterType).toList();
    }

    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((s) {
        return s.name.toLowerCase().contains(q) ||
            s.contactName.toLowerCase().contains(q) ||
            s.phone.toLowerCase().contains(q) ||
            s.address.toLowerCase().contains(q) ||
            s.type.toLowerCase().contains(q);
      }).toList();
    }

    // Избранные сверху, потом по имени
    list.sort((a, b) {
      if (a.favorite != b.favorite) {
        return a.favorite ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return list;
  }

  List<String> get _allTypes {
    final set = <String>{};
    for (final s in services) {
      if (s.type.trim().isNotEmpty) set.add(s.type.trim());
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<void> _call(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: clean);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openAddress(String address) async {
    if (address.isEmpty) return;
    final uri = Uri.parse(
      'https://yandex.ru/maps/?text=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _add() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceFormScreen(
          onSave: (s) {
            setState(() => services.add(s));
            _persist();
          },
        ),
      ),
    );
  }

  void _edit(Service s) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceFormScreen(
          service: s,
          onSave: (updated) {
            setState(() {
              final idx = services.indexWhere((x) => x.id == updated.id);
              if (idx >= 0) services[idx] = updated;
            });
            _persist();
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Service s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить контакт?'),
        content: Text(s.name),
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
    if (ok == true) {
      setState(() => services.removeWhere((x) => x.id == s.id));
      _persist();
    }
  }

  Future<void> _toggleFavorite(Service s) async {
    setState(() {
      final idx = services.indexWhere((x) => x.id == s.id);
      if (idx >= 0) {
        services[idx] = s.copyWith(favorite: !s.favorite);
      }
    });
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final visible = _filtered();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сервис-контакты'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Добавить'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: TextField(
              controller: searchController,
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(
                hintText: 'Поиск: имя, телефон, тип…',
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
          if (_allTypes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: const Text('Все'),
                        selected: filterType.isEmpty,
                        onSelected: (_) =>
                            setState(() => filterType = ''),
                      ),
                    ),
                    ..._allTypes.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(t),
                          selected: filterType == t,
                          onSelected: (_) => setState(() {
                            filterType =
                                filterType == t ? '' : t;
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
          Expanded(
            child: visible.isEmpty
                ? EmptyState(
                    icon: Icons.contacts_outlined,
                    title: search.isNotEmpty
                        ? 'Ничего не найдено'
                        : 'Контактов пока нет',
                    subtitle: search.isEmpty
                        ? 'Добавьте СТО, магазины запчастей или оценщиков'
                        : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final s = visible[index];
                      final color = serviceTypeColor(s.type);
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 5),
                        child: PaddedCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: color
                                          .withValues(alpha: 0.14),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.business_outlined,
                                      color: color,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.name,
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight:
                                                FontWeight.w800,
                                          ),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                        if (s.type.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.withValues(
                                                  alpha: 0.14),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      8),
                                            ),
                                            child: Text(
                                              s.type,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight.w700,
                                                color: color,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      s.favorite
                                          ? Icons.star_rounded
                                          : Icons
                                              .star_border_rounded,
                                      color: s.favorite
                                          ? const Color(0xFFF59E0B)
                                          : theme.colorScheme
                                              .onSurfaceVariant,
                                    ),
                                    onPressed: () =>
                                        _toggleFavorite(s),
                                  ),
                                ],
                              ),
                              if (s.contactName.isNotEmpty ||
                                  s.phone.isNotEmpty ||
                                  s.address.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                if (s.contactName.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 2),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.person_outline,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(s.contactName),
                                      ],
                                    ),
                                  ),
                                if (s.phone.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 2),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.phone_outlined,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(s.phone),
                                      ],
                                    ),
                                  ),
                                if (s.address.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 2),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(s.address),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                              if (s.notes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  s.notes,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: theme.colorScheme
                                        .onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (s.phone.isNotEmpty)
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () =>
                                            _call(s.phone),
                                        icon: const Icon(
                                          Icons.phone,
                                          size: 16,
                                        ),
                                        label:
                                            const Text('Позвонить'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: color,
                                          minimumSize:
                                              const Size.fromHeight(
                                                  40),
                                        ),
                                      ),
                                    ),
                                  if (s.phone.isNotEmpty &&
                                      s.address.isNotEmpty)
                                    const SizedBox(width: 8),
                                  if (s.address.isNotEmpty)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _openAddress(s.address),
                                        icon: const Icon(
                                          Icons.map_outlined,
                                          size: 16,
                                        ),
                                        label: const Text('Карта'),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize:
                                              const Size.fromHeight(
                                                  40),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () => _edit(s),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                      ),
                                      label: const Text('Изменить'),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () =>
                                          _confirmDelete(s),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 16,
                                        color: Color(0xFFEF4444),
                                      ),
                                      label: const Text(
                                        'Удалить',
                                        style: TextStyle(
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
          
