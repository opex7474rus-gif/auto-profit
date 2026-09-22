import 'package:flutter/material.dart';

import 'car.dart';
import 'constants.dart';
import 'models.dart';
import 'utils.dart';
import 'widgets_ui.dart';

class ExpensesBlock extends StatelessWidget {
  final Car car;
  final VoidCallback onChanged;

  const ExpensesBlock({super.key, required this.car, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PaddedCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Расходы',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => showExpenseDialogWrapper(
                  context: context,
                  car: car,
                  onChanged: onChanged,
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (car.expenses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Расходов пока нет',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...car.expenses.map(
              (expense) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                ),
                title: Text(
                  expense.category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  expense.note.isEmpty
                      ? 'Нажмите, чтобы изменить'
                      : expense.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  money(expense.amount),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => showExpenseDialogWrapper(
                  context: context,
                  car: car,
                  expense: expense,
                  onChanged: onChanged,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> showExpenseDialogWrapper({
  required BuildContext context,
  required Car car,
  Expense? expense,
  required VoidCallback onChanged,
}) async {
  final amount = TextEditingController(
    text: expense != null ? expense.amount.toStringAsFixed(0) : '',
  );
  final note = TextEditingController(text: expense?.note ?? '');
  String category = expense?.category ?? kExpenseCategories.first;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: Text(
              expense == null ? 'Добавить расход' : 'Изменить расход',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(
                      labelText: 'Категория',
                    ),
                    items: kExpenseCategories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setLocal(() => category = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Сумма',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: note,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Комментарий',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (expense != null)
                TextButton(
                  onPressed: () {
                    car.expenses.removeWhere((e) => e.id == expense.id);
                    onChanged();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Удалить',
                    style: TextStyle(color: Color(0xFFEF4444)),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () {
                  final value = double.tryParse(
                        amount.text.replaceAll(',', '.'),
                      ) ??
                      0;
                  if (value <= 0) return;
                  if (expense == null) {
                    car.expenses.add(
                      Expense(
                        id: newId(),
                        category: category,
                        amount: value,
                        note: note.text.trim(),
                      ),
                    );
                  } else {
                    expense.category = category;
                    expense.amount = value;
                    expense.note = note.text.trim();
                  }
                  onChanged();
                  Navigator.pop(dialogContext);
                },
                child: Text(expense == null ? 'Добавить' : 'Сохранить'),
              ),
            ],
          );
        },
      );
    },
  );
}
