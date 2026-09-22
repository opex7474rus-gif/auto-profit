import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'car.dart';
import 'contract_html.dart';
import 'storage.dart';

class ContractDialog extends StatefulWidget {
  final Car car;
  const ContractDialog({super.key, required this.car});

  @override
  State<ContractDialog> createState() => _ContractDialogState();
}

class _ContractDialogState extends State<ContractDialog> {
  final sellerFio = TextEditingController();
  final sellerPassport = TextEditingController();
  final sellerAddress = TextEditingController();
  final sellerPhone = TextEditingController();
  final buyerFio = TextEditingController();
  final buyerPassport = TextEditingController();
  final buyerAddress = TextEditingController();
  final buyerPhone = TextEditingController();
  final priceController = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    priceController.text = widget.car.sale > 0
        ? widget.car.sale.toStringAsFixed(0)
        : widget.car.invested.toStringAsFixed(0);
    _load();
  }

  Future<void> _load() async {
    final seller = await Storage.loadSellerData();
    final buyer = await Storage.loadBuyerData();
    sellerFio.text = seller['fio'] ?? '';
    sellerPassport.text = seller['passport'] ?? '';
    sellerAddress.text = seller['address'] ?? '';
    sellerPhone.text = seller['phone'] ?? '';
    buyerFio.text = buyer['fio'] ?? '';
    buyerPassport.text = buyer['passport'] ?? '';
    buyerAddress.text = buyer['address'] ?? '';
    buyerPhone.text = buyer['phone'] ?? '';
    if (!mounted) return;
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    sellerFio.dispose();
    sellerPassport.dispose();
    sellerAddress.dispose();
    sellerPhone.dispose();
    buyerFio.dispose();
    buyerPassport.dispose();
    buyerAddress.dispose();
    buyerPhone.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final sellerData = {
      'fio': sellerFio.text.trim(),
      'passport': sellerPassport.text.trim(),
      'address': sellerAddress.text.trim(),
      'phone': sellerPhone.text.trim(),
    };
    final buyerData = {
      'fio': buyerFio.text.trim(),
      'passport': buyerPassport.text.trim(),
      'address': buyerAddress.text.trim(),
      'phone': buyerPhone.text.trim(),
    };
    await Storage.saveSellerData(sellerData);
    await Storage.saveBuyerData(buyerData);
    await saveContractHtml(
      widget.car,
      sellerData,
      buyerData,
      priceController.text.trim(),
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Договор сформирован')),
    );
  }

  Widget _dlgField(
    TextEditingController c,
    String label, {
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
        ),
      ),
    );
    }
  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Договор купли-продажи',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.car.make} ${widget.car.model}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 24),
            const Text(
              'Продавец',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _dlgField(sellerFio, 'ФИО'),
            _dlgField(sellerPassport, 'Паспорт'),
            _dlgField(sellerAddress, 'Адрес регистрации'),
            _dlgField(sellerPhone, 'Телефон'),
            const Divider(height: 24),
            const Text(
              'Покупатель',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _dlgField(buyerFio, 'ФИО'),
            _dlgField(buyerPassport, 'Паспорт'),
            _dlgField(buyerAddress, 'Адрес регистрации'),
            _dlgField(buyerPhone, 'Телефон'),
            const Divider(height: 24),
            _dlgField(priceController, 'Цена продажи (₽)', number: true),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _generate,
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('Сформировать'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  }
