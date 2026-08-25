import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/models/sale_model.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Пункты меню «…» на экране продажи.
///
/// [priceMode], [currency], [debtRepayment] и [expense] к текущему чеку
/// не относятся и живут в меню шапки; остальное — в меню блока итогов.
enum SaleAction {
  priceMode,
  currency,
  debtRepayment,
  expense,
  selectClient,
  createClient,
  clearCheque,
}

/// Иконки быстрых операций в меню «…».
extension _ShortcutIcon on SaleShortcut {
  IconData get icon => switch (this) {
        SaleShortcut.quantity => UniconsLine.layer_group,
        SaleShortcut.lineTotal => UniconsLine.calculator_alt,
        SaleShortcut.price => UniconsLine.money_bill,
        SaleShortcut.unit => UniconsLine.box,
        SaleShortcut.discountPercent => UniconsLine.percentage,
        SaleShortcut.discountLine => UniconsLine.tag_alt,
        SaleShortcut.discountAmount => UniconsLine.receipt_alt,
      };
}

/// Модальные листы экрана продажи.
///
/// Каждый лист — тонкая обёртка над [AppModal.sheet]: состояние живёт
/// в [SaleModel], лист только рисует его и вызывает методы модели.
class SaleSheets {
  const SaleSheets._();

  /// Меню чека («…» в блоке итогов): операции над позициями, клиенты, очистка.
  ///
  /// Возвращает либо [SaleShortcut] (операция запросит значение отдельным
  /// листом), либо [SaleAction].
  static Future<Object?> chequeActions(BuildContext context, SaleModel model) {
    return AppModal.actions<Object>(
      context,
      title: context.tr('cheque'),
      cancelLabel: context.tr('cancel'),
      actions: [
        if (!model.isEmpty)
          for (final shortcut in SaleShortcut.menu)
            AppModalAction(
              label: context.tr(shortcut.labelKey),
              value: shortcut,
              icon: shortcut.icon,
            ),
        if (model.isAgent)
          AppModalAction(
            label: context.tr('choose_client'),
            value: SaleAction.selectClient,
            icon: UniconsLine.user,
          ),
        if (model.isAgent)
          AppModalAction(
            label: context.tr('create_client'),
            value: SaleAction.createClient,
            icon: UniconsLine.user_plus,
          ),
        if (!model.isEmpty && checkRole('CASHBOX_DELETE_SCAN_ITEM'))
          AppModalAction(
            label: context.tr('clear'),
            value: SaleAction.clearCheque,
            icon: UniconsLine.trash_alt,
            danger: true,
          ),
      ],
    );
  }

  /// Меню кассы («…» в шапке): то, что не относится к текущему чеку —
  /// режим цены, валюта, погашение долга, расходы.
  static Future<SaleAction?> cashierActions(BuildContext context, SaleModel model) {
    return AppModal.actions<SaleAction>(
      context,
      title: context.tr('more'),
      cancelLabel: context.tr('cancel'),
      actions: [
        AppModalAction(
          label: '${context.tr('price')}: ${context.tr(model.priceMode.labelKey)}',
          value: SaleAction.priceMode,
          icon: UniconsLine.tag_alt,
        ),
        if (model.currencyChangeAllowed)
          AppModalAction(
            label: '${context.tr('currency')}: ${model.currencyName}',
            value: SaleAction.currency,
            icon: UniconsLine.exchange,
          ),
        if (!model.isAgent)
          AppModalAction(
            label: context.tr('amortization'),
            value: SaleAction.debtRepayment,
            icon: UniconsLine.credit_card,
          ),
        if (!model.isAgent && checkRole('CASHBOX_EXPENSE'))
          AppModalAction(
            label: context.tr('expenses'),
            value: SaleAction.expense,
            icon: UniconsLine.usd_circle,
          ),
      ],
    );
  }

  /// Значение для быстрой операции: открывается после выбора операции
  /// в меню «…». Возвращает введённое число или `null`, если отменили.
  static Future<String?> shortcutValue(BuildContext context, SaleShortcut shortcut) {
    return AppModal.sheet<String>(
      context,
      builder: (ctx) => _ShortcutValueSheet(shortcut: shortcut),
    );
  }

  /// Выбор режима цены: розница / опт / банк.
  static Future<void> priceMode(BuildContext context, SaleModel model) {
    return AppModal.sheet<void>(
      context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.tr('price'), style: AppText.h2),
          const SizedBox(height: AppDimens.gap12),
          for (final mode in SalePriceMode.values) ...[
            AppCard(
              selected: mode == model.priceMode,
              onTap: () {
                model.setPriceMode(mode);
                Navigator.of(ctx).pop();
              },
              child: Row(
                children: [
                  Expanded(child: Text(context.tr(mode.labelKey), style: AppText.bodyMedium)),
                  if (mode == model.priceMode)
                    Icon(UniconsLine.check, size: 20, color: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.gap8),
          ],
        ],
      ),
    );
  }

  /// Диалог товара с упаковкой: «упаковок» + «штук из упаковки».
  static Future<void> unit(BuildContext context, SaleModel model) {
    return AppModal.sheet<void>(
      context,
      builder: (ctx) => _UnitSheet(model: model),
    );
  }

  /// Расход из кассы.
  static Future<void> expense(BuildContext context, SaleModel model) {
    return AppModal.sheet<void>(
      context,
      builder: (ctx) => _ExpenseSheet(model: model),
    );
  }

  /// Погашение долга клиента.
  static Future<void> debt(BuildContext context, SaleModel model) async {
    await model.loadDebtClients();
    if (!context.mounted) return;
    await AppModal.sheet<void>(
      context,
      builder: (ctx) => _DebtSheet(model: model),
    );
    model.resetDebtForm();
  }

  /// Выбор клиента (агент).
  static Future<void> selectClient(BuildContext context, SaleModel model) async {
    await model.loadClients();
    if (!context.mounted) return;
    final picked = await AppModal.sheet<bool>(
      context,
      builder: (ctx) => _ClientPickerSheet(model: model),
    );
    if (picked == true) model.attachSelectedClient();
  }

  /// Создание клиента (агент).
  static Future<void> createClient(BuildContext context, SaleModel model) {
    return AppModal.sheet<void>(
      context,
      builder: (ctx) => _CreateClientSheet(model: model),
    );
  }
}

/// Заголовок листа: название и кнопка закрытия.
class _SheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SheetHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.h2),
              if (subtitle != null) ...[
                const SizedBox(height: AppDimens.gap4),
                Text(subtitle!, style: AppText.small),
              ],
            ],
          ),
        ),
        AppIconButton(
          icon: Icons.close,
          foreground: AppColors.textSecondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

// --- Значение быстрой операции ----------------------------------------------

class _ShortcutValueSheet extends StatefulWidget {
  final SaleShortcut shortcut;

  const _ShortcutValueSheet({required this.shortcut});

  @override
  State<_ShortcutValueSheet> createState() => _ShortcutValueSheetState();
}

class _ShortcutValueSheetState extends State<_ShortcutValueSheet> {
  final _value = TextEditingController();

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _value.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SheetHeader(title: context.tr(widget.shortcut.labelKey)),
        const SizedBox(height: AppDimens.gap16),
        AppInput.money(
          controller: _value,
          hint: context.tr('enter_value'),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppDimens.gap16),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _value,
          builder: (context, value, _) => AppButton(
            label: context.tr('accept'),
            onPressed: value.text.trim().isEmpty ? null : _submit,
          ),
        ),
      ],
    );
  }
}

// --- Упаковка ---------------------------------------------------------------

class _UnitSheet extends StatefulWidget {
  final SaleModel model;

  const _UnitSheet({required this.model});

  @override
  State<_UnitSheet> createState() => _UnitSheetState();
}

class _UnitSheetState extends State<_UnitSheet> {
  final _packaging = TextEditingController();
  final _piece = TextEditingController();

  @override
  void dispose() {
    _packaging.dispose();
    _piece.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;

    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        // Модель может обнулить «штуки», если ввели больше, чем в упаковке.
        if (model.pieceInput != _piece.text) _piece.text = model.pieceInput;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHeader(
              title: '${model.productWithParams['productName'] ?? ''}',
              subtitle: '${context.tr('in_package')}: '
                  '${formatMoney(model.productWithParams['selectedUnit']['quantity'])}',
            ),
            const SizedBox(height: AppDimens.gap16),
            AppInput.money(
              label: context.tr('quantity'),
              controller: _packaging,
              onChanged: model.setPackaging,
            ),
            const SizedBox(height: AppDimens.gap12),
            AppInput.money(
              label: context.tr('from_package'),
              controller: _piece,
              onChanged: model.setPiece,
            ),
            const SizedBox(height: AppDimens.gap16),
            AppCard(
              child: Column(
                children: [
                  _SummaryRow(
                    label: context.tr('price'),
                    value: formatMoney(model.productWithParams['salePrice']),
                  ),
                  const SizedBox(height: AppDimens.gap8),
                  _SummaryRow(
                    label: context.tr('quantity'),
                    value: formatMoney(model.unitQuantity, decimalDigits: 3),
                  ),
                  const SizedBox(height: AppDimens.gap8),
                  _SummaryRow(
                    label: context.tr('to_pay'),
                    value: '${formatMoney(model.unitTotalPrice)} ${model.currencyName}',
                    accent: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.gap16),
            AppButton(
              label: context.tr('accept'),
              onPressed: model.canAddUnit
                  ? () {
                      model.confirmUnit();
                      Navigator.of(context).pop();
                    }
                  : null,
            ),
          ],
        );
      },
    );
  }
}

/// Строка «подпись — значение» внутри карточки итогов.
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.secondary),
        Text(
          value,
          style: accent
              ? AppText.price.copyWith(color: AppColors.primary)
              : AppText.tabular(AppText.bodyMedium),
        ),
      ],
    );
  }
}

// --- Расход -----------------------------------------------------------------

class _ExpenseSheet extends StatelessWidget {
  final SaleModel model;

  const _ExpenseSheet({required this.model});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(title: context.tr('expenses')),
          const SizedBox(height: AppDimens.gap16),
          AppSectionLabel(context.tr('type')),
          const SizedBox(height: AppDimens.gap8),
          Wrap(
            spacing: AppDimens.gap8,
            runSpacing: AppDimens.gap8,
            children: [
              for (final expense in model.expenses)
                AppChip(
                  label: '${expense['name']}',
                  selected: '${expense['id']}' == '${model.expenseOut['expenseId']}',
                  onTap: () => model.setExpenseField('expenseId', '${expense['id']}'),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.gap16),
          AppInput.money(
            label: '${context.tr('cash')} (${model.currencyName})',
            onChanged: (value) => model.setExpenseField('amountOut', value),
          ),
          const SizedBox(height: AppDimens.gap12),
          AppInput(
            label: context.tr('note'),
            hint: context.tr('note'),
            onChanged: (value) => model.setExpenseField('note', value),
          ),
          const SizedBox(height: AppDimens.gap16),
          AppButton(
            label: context.tr('accept'),
            loading: model.busy,
            onPressed: model.canSubmitExpense
                ? () async {
                    final ok = await model.submitExpense();
                    if (ok && context.mounted) Navigator.of(context).pop();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// --- Погашение долга --------------------------------------------------------

class _DebtSheet extends StatefulWidget {
  final SaleModel model;

  const _DebtSheet({required this.model});

  @override
  State<_DebtSheet> createState() => _DebtSheetState();
}

class _DebtSheetState extends State<_DebtSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(title: context.tr('amortization')),
          const SizedBox(height: AppDimens.gap12),
          AppSearchField(
            controller: _search,
            hint: context.tr('search'),
            onChanged: model.searchDebtClients,
          ),
          const SizedBox(height: AppDimens.gap12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.28),
            child: model.clients.isEmpty
                ? AppEmptyState(
                    icon: UniconsLine.user,
                    title: context.tr('no_data'),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: model.clients.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppDimens.gap8),
                    itemBuilder: (context, i) {
                      final client = model.clients[i];
                      return AppCard(
                        selected: client['selected'] == true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.gap12,
                          vertical: 10,
                        ),
                        onTap: () => model.selectDebtClient(i),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${client['clientName']}', style: AppText.bodyMedium),
                                  Text('${client['phone1'] ?? ''}', style: AppText.small),
                                ],
                              ),
                            ),
                            Text(
                              '${formatMoney(client['balance'])} ${client['currencyName'] ?? ''}',
                              style: AppText.tabular(AppText.secondaryBold),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppDimens.gap16),
          AppInput.money(
            label: context.tr('cash'),
            onChanged: (value) => model.setDebtField('cash', value),
          ),
          const SizedBox(height: AppDimens.gap12),
          AppInput.money(
            label: context.tr('terminal'),
            onChanged: (value) => model.setDebtField('terminal', value),
          ),
          const SizedBox(height: AppDimens.gap16),
          AppButton(
            label: context.tr('accept'),
            loading: model.busy,
            onPressed: model.canSubmitDebt
                ? () async {
                    final ok = await model.submitDebt();
                    if (ok && context.mounted) Navigator.of(context).pop();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// --- Клиенты агента ---------------------------------------------------------

class _ClientPickerSheet extends StatefulWidget {
  final SaleModel model;

  const _ClientPickerSheet({required this.model});

  @override
  State<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<_ClientPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(title: context.tr('choose_client')),
          const SizedBox(height: AppDimens.gap12),
          AppSearchField(
            controller: _search,
            hint: context.tr('search'),
            onChanged: model.searchClients,
          ),
          const SizedBox(height: AppDimens.gap12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: model.clients.isEmpty
                ? AppEmptyState(icon: UniconsLine.user, title: context.tr('no_data'))
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: model.clients.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppDimens.gap8),
                    itemBuilder: (context, i) {
                      final client = model.clients[i];
                      return AppCard(
                        selected: client['selected'] == true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.gap12,
                          vertical: 10,
                        ),
                        onTap: () => model.selectClient(i),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${client['name']}', style: AppText.bodyMedium),
                            Text(
                              '${client['phone1'] ?? ''} ${client['comment'] ?? ''}'.trim(),
                              style: AppText.small,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppDimens.gap16),
          AppButton(
            label: context.tr('choose'),
            onPressed: model.clients.any((e) => e['selected'] == true)
                ? () => Navigator.of(context).pop(true)
                : null,
          ),
        ],
      ),
    );
  }
}

class _CreateClientSheet extends StatefulWidget {
  final SaleModel model;

  const _CreateClientSheet({required this.model});

  @override
  State<_CreateClientSheet> createState() => _CreateClientSheetState();
}

class _CreateClientSheetState extends State<_CreateClientSheet> {
  final Map<String, String> _form = {
    'name': '',
    'phone1': '',
    'phone2': '',
    'address': '',
    'comment': '',
  };

  bool get _valid => _form['name']!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final fields = [
      ('name', 'contact_name', TextInputType.text),
      ('phone1', 'phone', TextInputType.phone),
      ('phone2', 'phone', TextInputType.phone),
      ('address', 'address', TextInputType.text),
      ('comment', 'comment', TextInputType.text),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SheetHeader(title: context.tr('create_client')),
        const SizedBox(height: AppDimens.gap16),
        for (final field in fields) ...[
          AppInput(
            label: context.tr(field.$2),
            keyboardType: field.$3,
            onChanged: (value) => setState(() => _form[field.$1] = value),
          ),
          const SizedBox(height: AppDimens.gap12),
        ],
        const SizedBox(height: AppDimens.gap4),
        AppButton(
          label: context.tr('save'),
          loading: widget.model.busy,
          onPressed: _valid
              ? () async {
                  final ok = await widget.model.createClient(_form);
                  if (ok && context.mounted) Navigator.of(context).pop();
                }
              : null,
        ),
      ],
    );
  }
}
