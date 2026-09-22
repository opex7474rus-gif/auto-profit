import 'package:flutter/material.dart';

import 'autocomplete_field.dart';
import 'car.dart';
import 'constants.dart';
import 'utils.dart';
import 'widgets_ui.dart';

class CarFormScreen extends StatefulWidget {
  final Car? car;
  final void Function(Car car) onSave;

  const CarFormScreen({
    super.key,
    this.car,
    required this.onSave,
  });

  @override
  State<CarFormScreen> createState() => _CarFormScreenState();
}

class _CarFormScreenState extends State<CarFormScreen> {
  final make = TextEditingController();
  final model = TextEditingController();
  final year = TextEditingController();
  final vin = TextEditingController();
  final plate = TextEditingController();
  final mileage = TextEditingController();
  final purchase = TextEditingController();
  final seller = TextEditingController();
  final sellerPhone = TextEditingController();
  final sellerAddress = TextEditingController();
  final notes = TextEditingController();
  final partnerInvestment = TextEditingController();

  final makeFocus = FocusNode();
  final modelFocus = FocusNode();
  final yearFocus = FocusNode();
  final vinFocus = FocusNode();
  final plateFocus = FocusNode();
  final mileageFocus = FocusNode();
  final purchaseFocus = FocusNode();
  final sellerFocus = FocusNode();
  final sellerPhoneFocus = FocusNode();
  final sellerAddressFocus = FocusNode();
  final notesFocus = FocusNode();
  final partnerFocus = FocusNode();

  String status = 'Куплен';
  DateTime? purchaseDate;
  final Set<String> tags = {};

  bool get isEdit => widget.car != null;

  @override
  void initState() {
    super.initState();
    final c = widget.car;
    if (c != null) {
      make.text = c.make;
      model.text = c.model;
      year.text = c.year;
      vin.text = c.vin;
      plate.text = c.plate;
      mileage.text = c.mileage;
      purchase.text = c.purchasePrice;
      seller.text = c.seller;
      sellerPhone.text = c.sellerPhone;
      sellerAddress.text = c.sellerAddress;
      notes.text = c.notes;
      partnerInvestment.text = c.partnerInvestment;
      status = c.status;
      purchaseDate = c.purchaseDateTime;
      tags.addAll(c.tags);
    } else {
      purchaseDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    make.dispose();
    model.dispose();
    year.dispose();
    vin.dispose();
    plate.dispose();
    mileage.dispose();
    purchase.dispose();
    seller.dispose();
    sellerPhone.dispose();
    sellerAddress.dispose();
    notes.dispose();
    partnerInvestment.dispose();
    makeFocus.dispose();
    modelFocus.dispose();
    yearFocus.dispose();
    vinFocus.dispose();
    plateFocus.dispose();
    mileageFocus.dispose();
    purchaseFocus.dispose();
    sellerFocus.dispose();
    sellerPhoneFocus.dispose();
    sellerAddressFocus.dispose();
    notesFocus.dispose();
    partnerFocus.dispose();
    super.dispose();
  }

  Future<void> pickPurchaseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: purchaseDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => purchaseDate = picked);
  }

  Future<void> _addCustomTag() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Свой тег'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Название'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => tags.add(result));
    }
  }

  void save() {
    if (make.text.trim().isEmpty || model.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите марку и модель')),
      );
      return;
    }
    final iso = purchaseDate == null ? '' : dateToIso(purchaseDate!);

    if (isEdit) {
      final c = widget.car!;
      if (c.status != status) c.statusChangedAt = todayIso();
      c.make = make.text.trim();
      c.model = model.text.trim();
      c.year = year.text.trim();
      c.vin = vin.text.trim();
      c.plate = plate.text.trim();
      c.mileage = mileage.text.trim();
      c.purchasePrice = purchase.text.trim();
      c.purchaseDate = iso;
      c.status = status;
      c.seller = seller.text.trim();
      c.sellerPhone = sellerPhone.text.trim();
      c.sellerAddress = sellerAddress.text.trim();
      c.notes = notes.text.trim();
      c.partnerInvestment = partnerInvestment.text.trim();
      c.tags = tags.toList();
      widget.onSave(c);
    } else {
      widget.onSave(
        Car(
          id: newId(),
          make: make.text.trim(),
          model: model.text.trim(),
          year: year.text.trim(),
          vin: vin.text.trim(),
          plate: plate.text.trim(),
          mileage: mileage.text.trim(),
          purchasePrice: purchase.text.trim(),
          purchaseDate: iso,
          status: status,
          statusChangedAt: todayIso(),
          seller: seller.text.trim(),
          sellerPhone: sellerPhone.text.trim(),
          sellerAddress: sellerAddress.text.trim(),
          notes: notes.text.trim(),
          salePrice: '',
          saleDate: '',
          partnerInvestment: partnerInvestment.text.trim(),
          tags: tags.toList(),
          expenses: [],
          photos: [],
          attachments: [],
        ),
      );
    }
    Navigator.pop(context);
  }

  Widget _field(
    TextEditingController controller,
    FocusNode focusNode,
    String label, {
    bool number = false,
    int lines = 1,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: lines,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
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
    final allTagOptions = <String>{
      ...kTagSuggestions,
      ...tags,
    }.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Редактировать авто' : 'Новый автомобиль',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          const SectionTitle(
            text: 'Автомобиль',
            icon: Icons.directions_car_outlined,
          ),
          AutocompleteField(
            controller: make,
            focusNode: makeFocus,
            label: 'Марка',
            optionsBuilder: (q) {
              final lower = q.toLowerCase();
              return kCarCatalog.keys
                  .where((m) => m.toLowerCase().contains(lower));
            },
            onChangedCallback: () => setState(() {}),
          ),
          AutocompleteField(
            controller: model,
            focusNode: modelFocus,
            label: 'Модель',
            optionsBuilder: (q) {
              final brand = make.text.trim();
              final lower = q.toLowerCase();
              if (brand.isEmpty) {
                final all = kCarCatalog.values
                    .expand((e) => e)
                    .toSet()
                    .toList();
                return all
                    .where((m) => m.toLowerCase().contains(lower));
              }
              final models = kCarCatalog[brand] ?? [];
              return models
                  .where((m) => m.toLowerCase().contains(lower));
            },
          ),
          AutocompleteField(
            controller: year,
            focusNode: yearFocus,
            label: 'Год',
            optionsBuilder: (q) =>
                kYearList.where((y) => y.startsWith(q)),
          ),
          _field(vin, vinFocus, 'VIN',
              icon: Icons.confirmation_number_outlined),
          _field(plate, plateFocus, 'Госномер',
              icon: Icons.directions_car_outlined),
          _field(mileage, mileageFocus, 'Пробег',
              icon: Icons.speed_outlined),
          const SectionTitle(
            text: 'Финансы',
            icon: Icons.account_balance_wallet_outlined,
          ),
          _field(purchase, purchaseFocus, 'Цена покупки',
              number: true, icon: Icons.attach_money),
          _field(
            partnerInvestment,
            partnerFocus,
            'Доля партнёра (₽) — прибыль 33%',
            number: true,
            icon: Icons.handshake_outlined,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: pickPurchaseDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Дата покупки',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  purchaseDate == null
                      ? 'Не указана'
                      : formatDate(purchaseDate!),
                ),
              ),
            ),
          ),
          const SectionTitle(
            text: 'Продавец',
            icon: Icons.person_outline,
          ),
          _field(seller, sellerFocus, 'Имя',
              icon: Icons.person_outline),
          _field(sellerPhone, sellerPhoneFocus, 'Телефон',
              number: true, icon: Icons.phone_outlined),
          _field(sellerAddress, sellerAddressFocus, 'Адрес / город',
              icon: Icons.location_on_outlined),
          const SectionTitle(
            text: 'Прочее',
            icon: Icons.notes_outlined,
          ),
          _field(notes, notesFocus, 'Примечания', lines: 4),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(
              labelText: 'Статус',
              prefixIcon: Icon(Icons.flag_outlined, size: 20),
            ),
            items: kStatuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => status = value);
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Метки',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...allTagOptions.map(
                (t) => FilterChip(
                  label: Text(t),
                  selected: tags.contains(t),
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        tags.add(t);
                      } else {
                        tags.remove(t);
                      }
                    });
                  },
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('Свой'),
                onPressed: _addCustomTag,
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: save,
            icon: const Icon(Icons.check_rounded),
            label: Text(
              isEdit ? 'Сохранить изменения' : 'Сохранить автомобиль',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
