import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'car.dart';
import 'car_form_screen.dart';
import 'constants.dart';
import 'contract_dialog.dart';
import 'documents_block.dart';
import 'expenses_block.dart';
import 'partner.dart';
import 'partner_storage.dart';
import 'photos_block.dart';
import 'utils.dart';
import 'widgets_ui.dart';

class CarDetailsScreen extends StatefulWidget {
  final Car car;
  final VoidCallback onChanged;
  final VoidCallback onDelete;
  final void Function(Car) onDuplicate;

  const CarDetailsScreen({
    super.key,
    required this.car,
    required this.onChanged,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  final salePrice = TextEditingController();
  DateTime? saleDate;

  @override
  void initState() {
    super.initState();
    salePrice.text = widget.car.salePrice;
    saleDate = widget.car.saleDateTime;
  }

  @override
  void dispose() {
    salePrice.dispose();
    super.dispose();
  }

  Future<void> _call() async {
    final phone =
        widget.car.sellerPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openAddress() async {
    final addr = widget.car.sellerAddress;
    if (addr.isEmpty) return;
    final uri = Uri.parse(
      'https://yandex.ru/maps/?text=${Uri.encodeComponent(addr)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void saveSale() {
    setState(() {
      final price = salePrice.text.trim();
      widget.car.salePrice = price;
      final value = double.tryParse(price.replaceAll(',', '.')) ?? 0;
      if (value > 0) {
        widget.car.saleDate =
            saleDate == null ? todayIso() : dateToIso(saleDate!);
        if (widget.car.status != 'Продан') {
          widget.car.status = 'Продан';
          widget.car.statusChangedAt = todayIso();
        }
      } else {
        widget.car.saleDate = '';
        if (widget.car.status == 'Продан') {
          widget.car.status = 'На продаже';
          widget.car.statusChangedAt = todayIso();
        }
      }
    });
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сохранено')),
    );
  }

  Future<void> pickSaleDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: saleDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => saleDate = picked);
  }

  void editCar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarFormScreen(
          car: widget.car,
          onSave: (_) {
            setState(() {});
            widget.onChanged();
          },
        ),
      ),
    );
  }

  void duplicateCar() {
    final copy = widget.car.duplicate();
    widget.onDuplicate(copy);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Создана копия автомобиля')),
    );
    Navigator.pop(context);
  }

  void confirmDeleteCar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить автомобиль?'),
        content: const Text(
          'Автомобиль переместится в корзину. Восстановить можно в течение 30 дней.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              // Возврат доли партнёра как «Забрал»,
              // потому что машина выпадает из работы.
              final amount = widget.car.partnerAmount;
              if (amount > 0) {
                await PartnerStorage.saveTransaction(
                  PartnerTransaction(
                    id: newId(),
                    type: 'out',
                    amount: amount,
                    note:
                        'Возврат по машине (в корзину): ${widget.car.make} ${widget.car.model}',
                    date: todayIso(),
                  ),
                );
              }

              widget.onDelete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('В корзину'),
          ),
        ],
      ),
    );
  }

  Future<void> generateContract() async {
    await showDialog(
      context: context,
      builder: (_) => ContractDialog(car: widget.car),
    );
  }
    @override
  Widget build(BuildContext context) {
    final car = widget.car;

    return Scaffold(
      appBar: AppBar(
        title: Text('${car.make} ${car.model}'),
        actions: [
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 'edit') editCar();
              if (value == 'duplicate') duplicateCar();
              if (value == 'contract') generateContract();
              if (value == 'delete') confirmDeleteCar();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Редактировать'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'duplicate',
                child: ListTile(
                  leading: Icon(Icons.copy_outlined),
                  title: Text('Дублировать'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'contract',
                child: ListTile(
                  leading: Icon(Icons.description_outlined),
                  title: Text('Сформировать ДКП'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline,
                      color: Color(0xFFEF4444)),
                  title: Text('В корзину',
                      style: TextStyle(color: Color(0xFFEF4444))),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          PhotosBlock(car: car, onChanged: widget.onChanged),
          const SizedBox(height: 12),
          PaddedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${car.make} ${car.model}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    StatusChip(status: car.status),
                  ],
                ),
                if (car.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: car.tags
                        .map(
                          (t) => Chip(
                            label: Text(
                              t,
                              style: const TextStyle(fontSize: 11.5),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                ],
                const Divider(),
                _infoRow('Год', car.year),
                _infoRow('VIN', car.vin),
                _infoRow('Госномер', car.plate),
                _infoRow('Пробег', car.mileage),
                _infoRow(
                  'Дата покупки',
                  car.purchaseDate.isEmpty
                      ? ''
                      : formatDate(car.purchaseDateTime!),
                ),
                _infoRow('На складе', '${car.daysInStock} дн.'),
                if (car.isStale)
                  _infoRow(
                    'В статусе',
                    '${car.daysInCurrentStatus} дн. (залежалась)',
                  ),
                if (car.saleDate.isNotEmpty)
                  _infoRow(
                    'Дата продажи',
                    formatDate(car.saleDateTime!),
                  ),
              ],
            ),
          ),
          if (car.seller.isNotEmpty ||
              car.sellerPhone.isNotEmpty ||
              car.sellerAddress.isNotEmpty) ...[
            const SectionTitle(
              text: 'Продавец',
              icon: Icons.person_outline,
            ),
            PaddedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (car.seller.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          car.seller,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  if (car.sellerPhone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 16),
                        const SizedBox(width: 8),
                        Text(car.sellerPhone),
                      ],
                    ),
                  ],
                  if (car.sellerAddress.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(car.sellerAddress)),
                      ],
                    ),
                  ],
                  if (car.sellerPhone.isNotEmpty ||
                      car.sellerAddress.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (car.sellerPhone.isNotEmpty)
                          FilledButton.icon(
                            onPressed: _call,
                            icon: const Icon(Icons.phone, size: 18),
                            label: const Text('Позвонить'),
                          ),
                        if (car.sellerAddress.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: _openAddress,
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: const Text('Карта'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SectionTitle(
            text: 'Финансы',
            icon: Icons.account_balance_wallet_outlined,
          ),
          PaddedCard(
            child: Column(
              children: [
                DetailRow(
                    label: 'Цена покупки', value: money(car.purchase)),
                DetailRow(
                    label: 'Расходы', value: money(car.expensesTotal)),
                const Divider(),
                DetailRow(
                  label: 'Всего вложено',
                  value: money(car.invested),
                  bold: true,
                  valueColor: const Color(0xFF4A4FC7),
                ),
                DetailRow(
                  label: 'Безубыточная цена',
                  value: money(car.breakEvenPrice),
                  bold: true,
                  valueColor: const Color(0xFFF59E0B),
                ),
                const Divider(),
                DetailRow(
                    label: 'Цена продажи', value: money(car.sale)),
                DetailRow(
                  label: 'Прибыль',
                  value: money(car.profit),
                  bold: true,
                  valueColor: car.profit >= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
                if (car.partnerAmount > 0) ...[
                  const Divider(),
                  DetailRow(
                    label: 'Доля партнёра (вложено)',
                    value: money(car.partnerAmount),
                    valueColor: const Color(0xFF9B5DE5),
                  ),
                  DetailRow(
                    label: 'Доля прибыли партнёра',
                    value:
                        '${car.partnerSharePercent.toStringAsFixed(0)}%',
                    valueColor: const Color(0xFF9B5DE5),
                  ),
                  DetailRow(
                    label: 'Прибыль партнёра',
                    value: money(car.partnerProfit),
                    bold: true,
                    valueColor: const Color(0xFF9B5DE5),
                  ),
                  DetailRow(
                    label: 'Прибыль вам',
                    value: money(car.isSold ? car.myProfit : 0),
                    bold: true,
                    valueColor: const Color(0xFF10B981),
                  ),
                ],
              ],
            ),
          ),
          const SectionTitle(
            text: 'Расходы',
            icon: Icons.receipt_long_outlined,
          ),
          ExpensesBlock(car: car, onChanged: widget.onChanged),
          const SectionTitle(
            text: 'Документы',
            icon: Icons.folder_outlined,
          ),
          DocumentsBlock(car: car, onChanged: widget.onChanged),
          const SectionTitle(
            text: 'Продажа',
            icon: Icons.sell_outlined,
          ),
          PaddedCard(
            child: Column(
              children: [
                TextField(
                  controller: salePrice,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Цена продажи',
                    prefixIcon: Icon(Icons.attach_money),
                    helperText:
                        'Оставьте пустым или 0, чтобы машина осталась в наличии',
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: pickSaleDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Дата продажи',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      saleDate == null
                          ? 'Не указана'
                          : formatDate(saleDate!),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: saveSale,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Сохранить продажу'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
          if (car.notes.isNotEmpty) ...[
            const SectionTitle(
              text: 'Примечания',
              icon: Icons.notes_outlined,
            ),
            PaddedCard(
              child: Text(car.notes,
                  style: const TextStyle(height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
