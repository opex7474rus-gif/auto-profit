import 'package:flutter/material.dart';

import 'car.dart';
import 'partner.dart';
import 'partner_storage.dart';
import 'utils.dart';
import 'widgets_ui.dart';

class PartnerScreen extends StatefulWidget {
  final List<Car> cars;
  const PartnerScreen({super.key, required this.cars});

  @override
  State<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends State<PartnerScreen> {
  PartnerSettings settings = PartnerSettings();
  List<PartnerTransaction> transactions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await PartnerStorage.loadSettings();
    final tx = await PartnerStorage.loadTransactions();
    if (!mounted) return;
    setState(() {
      settings = s;
      transactions = tx;
      loading = false;
    });
  }

  PartnerBalance _calculateBalance() {
    final partnerCars =
        widget.cars.where((c) => c.partnerAmount > 0).toList();
    final partnerStock = partnerCars.where((c) => !c.isSold).toList();
    final partnerSold = partnerCars.where((c) => c.isSold).toList();

    final investedInCars =
        partnerCars.fold(0.0, (s, c) => s + c.partnerAmount);
    final inWorkNow =
        partnerStock.fold(0.0, (s, c) => s + c.partnerAmount);
    final returned =
        partnerSold.fold(0.0, (s, c) => s + c.partnerAmount);
    final profitShare =
        partnerSold.fold(0.0, (s, c) => s + c.partnerProfit);

    double manualIn = 0;
    double manualOut = 0;
    for (final t in transactions) {
      if (t.isIn) {
        manualIn += t.amount;
      } else {
        manualOut += t.amount;
      }
    }

    return PartnerBalance(
      investedInCars: investedInCars,
      inWorkNow: inWorkNow,
      returned: returned,
      profitShare: profitShare,
      manualIn: manualIn,
      manualOut: manualOut,
    );
  }

  Future<void> _editSettings() async {
    final nameCtrl = TextEditingController(text: settings.name);
    final phoneCtrl = TextEditingController(text: settings.phone);
    final notesCtrl = TextEditingController(text: settings.notes);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Настройки партнёра'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Имя партнёра',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Заметка',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final s = PartnerSettings(
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        notes: notesCtrl.text.trim(),
      );
      await PartnerStorage.saveSettings(s);
      if (!mounted) return;
      setState(() => settings = s);
    }
  }

  Future<void> _addTransaction(bool isIn) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isIn ? 'Партнёр внёс деньги' : 'Партнёр забрал деньги',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Сумма, ₽',
                prefixIcon: Icon(
                  isIn
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: isIn
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Комментарий',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final value = double.tryParse(
            amountCtrl.text.replaceAll(',', '.'),
          ) ??
          0;
      if (value <= 0) return;
      final tx = PartnerTransaction(
        id: newId(),
        type: isIn ? 'in' : 'out',
        amount: value,
        note: noteCtrl.text.trim(),
        date: todayIso(),
      );
      await PartnerStorage.saveTransaction(tx);
      if (!mounted) return;
      setState(() => transactions.insert(0, tx));
    }
  }
    Future<void> _deleteTransaction(PartnerTransaction tx) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить операцию?'),
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
      await PartnerStorage.deleteTransaction(tx.id);
      if (!mounted) return;
      setState(() {
        transactions.removeWhere((t) => t.id == tx.id);
      });
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
    final b = _calculateBalance();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          settings.name.isEmpty ? 'Партнёр' : settings.name,
        ),
        actions: [
          IconButton(
            tooltip: 'Настройки',
            onPressed: _editSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _mainBalanceCard(b),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _addTransaction(true),
                  icon: const Icon(Icons.arrow_downward_rounded),
                  label: const Text('Внёс'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _addTransaction(false),
                  icon: const Icon(Icons.arrow_upward_rounded),
                  label: const Text('Забрал'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const SectionTitle(
            text: 'Детализация',
            icon: Icons.receipt_long_outlined,
          ),
          PaddedCard(
            child: Column(
              children: [
                DetailRow(
                  label: 'Вложено в машины',
                  value: money(b.investedInCars),
                  valueColor: const Color(0xFF4A4FC7),
                ),
                DetailRow(
                  label: 'В работе сейчас',
                  value: money(b.inWorkNow),
                  valueColor: const Color(0xFFFF7A45),
                ),
                DetailRow(
                  label: 'Вернулось из проданных',
                  value: money(b.returned),
                  valueColor: const Color(0xFF06B6D4),
                ),
                DetailRow(
                  label: 'Прибыль партнёра',
                  value: money(b.profitShare),
                  valueColor: const Color(0xFF10B981),
                ),
                const Divider(),
                DetailRow(
                  label: 'Внёс вручную',
                  value: money(b.manualIn),
                  valueColor: const Color(0xFF10B981),
                ),
                DetailRow(
                  label: 'Забрал вручную',
                  value: money(b.manualOut),
                  valueColor: const Color(0xFFEF4444),
                ),
                const Divider(),
                DetailRow(
                  label: 'Всего внёс',
                  value: money(b.totalIn),
                  bold: true,
                ),
                DetailRow(
                  label: 'Всего забрал',
                  value: money(b.totalOut),
                  bold: true,
                ),
              ],
            ),
          ),

          const SectionTitle(
            text: 'История операций',
            icon: Icons.history,
          ),
          if (transactions.isEmpty)
            PaddedCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Операций пока нет',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Если партнёр уже вносил деньги — нажмите '
                      '«Внёс» и введите сумму начального взноса. '
                      'Баланс пересчитается автоматически.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...transactions.map(
              (tx) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: PaddedCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (tx.isIn
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444))
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          tx.isIn
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: tx.isIn
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.isIn ? 'Внёс' : 'Забрал',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tx.note.isEmpty
                                  ? formatDate(
                                      DateTime.tryParse(tx.date) ??
                                          DateTime.now(),
                                    )
                                  : '${formatDate(DateTime.tryParse(tx.date) ?? DateTime.now())} · ${tx.note}',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme
                                    .colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            money(tx.amount),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: tx.isIn
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 18,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.grey,
                            ),
                            onPressed: () => _deleteTransaction(tx),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (settings.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            PaddedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Заметка о партнёре',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(settings.notes, style: const TextStyle(height: 1.5)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mainBalanceCard(PartnerBalance b) {
    final balance = b.balance;
    final isPositive = balance >= 0;
    final gradient = isPositive
        ? const [Color(0xFF10B981), Color(0xFF34D399)]
        : const [Color(0xFFEF4444), Color(0xFFF87171)];

    final label = isPositive
        ? 'Вы должны партнёру'
        : 'Партнёр должен вам';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            money(balance.abs()),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.savings_outlined,
                  size: 13,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  'Свободный остаток: ${money(b.freeBalance)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
