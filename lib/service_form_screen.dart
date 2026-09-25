import 'package:flutter/material.dart';

import 'service.dart';
import 'utils.dart';
import 'widgets_ui.dart';

class ServiceFormScreen extends StatefulWidget {
  final Service? service;
  final void Function(Service service) onSave;

  const ServiceFormScreen({
    super.key,
    this.service,
    required this.onSave,
  });

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final name = TextEditingController();
  final type = TextEditingController();
  final contactName = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final notes = TextEditingController();
  bool favorite = false;

  bool get isEdit => widget.service != null;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    if (s != null) {
      name.text = s.name;
      type.text = s.type;
      contactName.text = s.contactName;
      phone.text = s.phone;
      address.text = s.address;
      notes.text = s.notes;
      favorite = s.favorite;
    }
  }

  @override
  void dispose() {
    name.dispose();
    type.dispose();
    contactName.dispose();
    phone.dispose();
    address.dispose();
    notes.dispose();
    super.dispose();
  }

  void _save() {
    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название')),
      );
      return;
    }
    final s = Service(
      id: widget.service?.id ?? newId(),
      name: name.text.trim(),
      type: type.text.trim(),
      contactName: contactName.text.trim(),
      phone: phone.text.trim(),
      address: address.text.trim(),
      notes: notes.text.trim(),
      favorite: favorite,
    );
    widget.onSave(s);
    Navigator.pop(context);
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool number = false,
    int lines = 1,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: lines,
        keyboardType: number
            ? TextInputType.phone
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Редактировать контакт' : 'Новый контакт',
        ),
        actions: [
          IconButton(
            tooltip: favorite ? 'Убрать из избранного' : 'В избранное',
            onPressed: () => setState(() => favorite = !favorite),
            icon: Icon(
              favorite
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              color: favorite ? const Color(0xFFF59E0B) : null,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          const SectionTitle(
            text: 'Контакт',
            icon: Icons.business_outlined,
          ),
          _field(
            name,
            'Название (СТО «АвтоМастер»)',
            icon: Icons.business_outlined,
          ),
          _field(
            type,
            'Тип (СТО, магазин, оценщик…)',
            icon: Icons.label_outline,
          ),
          _field(
            contactName,
            'Имя контакта',
            icon: Icons.person_outline,
          ),
          _field(
            phone,
            'Телефон',
            number: true,
            icon: Icons.phone_outlined,
          ),
          _field(
            address,
            'Адрес',
            icon: Icons.location_on_outlined,
          ),
          _field(
            notes,
            'Заметка (график, специализация…)',
            lines: 4,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
            label: Text(
              isEdit ? 'Сохранить изменения' : 'Сохранить контакт',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}
