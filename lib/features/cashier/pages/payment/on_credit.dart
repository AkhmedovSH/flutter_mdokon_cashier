import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/models/cashbox_model.dart';
import 'package:flutter_mdokon/features/cashier/pages/payment/widgets/payment_widgets.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Вкладка «В долг»: клиент, комментарий и частичная оплата.
///
/// Клиент выбирается в нижнем листе — там же, не закрывая его, можно завести
/// нового: на телефоне переход в отдельный диалог терял контекст поиска.
class OnCredit extends StatefulWidget {
  const OnCredit({super.key});

  @override
  State<OnCredit> createState() => _OnCreditState();
}

class _OnCreditState extends State<OnCredit> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _commentController.text = context.read<CashboxModel>().clientComment;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _openClientSheet(CashboxModel model) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await model.fetchClients();
    if (!mounted) return;

    await AppModal.sheet(
      context,
      builder: (ctx) => ClientPickerSheet(model: model),
    );
  }

  // --- Срок возврата ------------------------------------------------------

  /// Дата возврата долга хранится в `data['clientReturnDate']` строкой
  /// `yyyy-MM-dd` — в этом же виде её ждёт бэкенд (как в десктопной кассе).
  DateTime? _returnDateOf(CashboxModel model) {
    final raw = '${model.data['clientReturnDate'] ?? ''}'.trim();
    return raw.isEmpty ? null : DateTime.tryParse(raw);
  }

  void _setReturnDate(CashboxModel model, DateTime? date) {
    model.setDataKey(
      'clientReturnDate',
      date == null ? '' : DateFormat('yyyy-MM-dd').format(date),
    );
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Срок в днях от сегодня — по нему подсвечивается быстрый выбор.
  int? _termDays(CashboxModel model) {
    return _returnDateOf(model)?.difference(_today).inDays;
  }

  Future<void> _pickReturnDate(CashboxModel model) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final current = _returnDateOf(model);
    final picked = await showDatePicker(
      context: context,
      // Долг возвращают в будущем — прошлые даты выбрать нельзя.
      firstDate: _today,
      lastDate: _today.add(const Duration(days: 365 * 3)),
      initialDate: current != null && current.isAfter(_today) ? current : _today.add(const Duration(days: 30)),
    );
    if (picked != null) _setReturnDate(model, picked);
  }

  Widget _returnDate(CashboxModel model) {
    final DateTime? date = _returnDateOf(model);
    final int? term = _termDays(model);
    const List<int> quickTerms = [7, 14, 30];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('return_date').toUpperCase(),
                style: AppText.caption.copyWith(color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppDimens.gap8),
            Text(
              date == null ? context.tr('not_specified') : DateFormat('dd.MM.yyyy').format(date),
              style: AppText.tabular(AppText.small).copyWith(
                color: date == null ? AppColors.iconMuted : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.gap8),
        Row(
          children: [
            for (final days in quickTerms) ...[
              Expanded(
                child: AppChip(
                  label: '$days ${context.tr('days_short')}',
                  selected: term == days,
                  onTap: () => _setReturnDate(model, _today.add(Duration(days: days))),
                ),
              ),
              const SizedBox(width: AppDimens.gap8),
            ],
            Expanded(
              child: AppChip(
                label: context.tr('other'),
                icon: Icons.calendar_month_outlined,
                selected: date != null && !quickTerms.contains(term),
                onTap: () => _pickReturnDate(model),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CashboxModel, PaymentUiState>(
      builder: (context, model, ui, child) {
        // change — «внесено минус к оплате»: отрицательный остаток уходит в долг.
        final double change = customNumber(model.data['change']);
        final double debt = change < 0 ? -change : 0;
        final String clientName = '${model.data['clientName'] ?? ''}'.trim();
        final bool hasClient = customIf(model.data['clientId']);
        final String currency = '${model.data['currencyName'] ?? ''}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClientBar(
              label: context.tr('client'),
              title: hasClient && clientName.isNotEmpty ? clientName : context.tr('choose'),
              subtitle: hasClient
                  ? '${context.tr('AMOUNT_OF_DEBT')} ${formatMoney(debt)} $currency'
                  : '${context.tr('clients')} · ${context.tr('search')}',
              action: hasClient ? context.tr('edit') : context.tr('search'),
              selected: hasClient,
              icon: Icons.person_outline,
              onTap: () => _openClientSheet(model),
            ),
            const SizedBox(height: AppDimens.gap12),
            _returnDate(model),
            const SizedBox(height: AppDimens.gap12),
            Text(
              context.tr('NOTE').toUpperCase(),
              style: AppText.caption.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            AppInput(
              hint: context.tr('comment'),
              controller: _commentController,
              maxLines: 2,
              height: 68,
              // Канва и поле в покое одного цвета — на экране оплаты поле
              // сливалось с фоном, поэтому держим его белым.
              fill: AppColors.surface,
              onChanged: (value) {
                // Как и раньше: комментарий уходит в data['comment'],
                // а в data['clientComment'] его переносит calculateChange().
                model.clientComment = value;
                model.setDataKey('comment', value);
              },
            ),
            const SizedBox(height: AppDimens.gap12),
            PaymentTypeTiles(model: model, ui: ui),
            if (!hasClient) ...[
              const SizedBox(height: AppDimens.gap12),
              AppBanner(
                title: context.tr('client'),
                text: context.tr('choose'),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Лист выбора клиента: поиск, встроенная форма нового клиента и список.
class ClientPickerSheet extends StatefulWidget {
  final CashboxModel model;

  const ClientPickerSheet({super.key, required this.model});

  @override
  State<ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<ClientPickerSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _newClientOpen = false;
  bool _saving = false;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = context.tr('required_field'));
      return;
    }

    setState(() {
      _saving = true;
      _nameError = null;
    });
    await widget.model.createNewClient({
      'name': _nameController.text.trim(),
      'phone1': _phoneController.text.trim(),
      'phone2': '',
      'address': '',
      'comment': '',
    });
    if (!mounted) return;

    setState(() {
      _saving = false;
      _newClientOpen = false;
    });
    _nameController.clear();
    _phoneController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CashboxModel>(
      builder: (context, model, child) {
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(context.tr('clients'), style: AppText.h2)),
                  AppButton(
                    label: context.tr('add'),
                    variant: _newClientOpen ? AppButtonVariant.soft : AppButtonVariant.secondary,
                    size: AppButtonSize.small,
                    expanded: false,
                    pill: true,
                    icon: _newClientOpen ? Icons.close : Icons.person_add_alt,
                    onPressed: () => setState(() => _newClientOpen = !_newClientOpen),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.gap12),
              AppInput(
                hint: context.tr('search'),
                height: AppDimens.heightMedium,
                prefixIcon: Icons.search,
                onChanged: model.searchClients,
              ),
              const SizedBox(height: AppDimens.gap12),
              if (_newClientOpen) ...[
                AppCard(
                  selected: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('add'), style: AppText.secondaryBold),
                      const SizedBox(height: 10),
                      AppInput(
                        hint: context.tr('contact_name'),
                        controller: _nameController,
                        errorText: _nameError,
                        height: AppDimens.heightMedium,
                      ),
                      const SizedBox(height: AppDimens.gap8),
                      AppInput(
                        hint: context.tr('phone'),
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        height: AppDimens.heightMedium,
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        label: context.tr('save'),
                        size: AppButtonSize.medium,
                        loading: _saving,
                        onPressed: _save,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.gap12),
              ],
              Expanded(
                child: model.clients.isEmpty
                    ? AppEmptyState(
                        icon: Icons.person_search_outlined,
                        title: context.tr('client_not_found'),
                        text: context.tr('search'),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: model.clients.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppDimens.gap8),
                        itemBuilder: (context, index) {
                          final client = model.clients[index];

                          return AppCard(
                            selected: client['selected'] == true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.gap16,
                              vertical: AppDimens.gap12,
                            ),
                            onTap: () {
                              model.selectClient(index);
                              Navigator.pop(context);
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${client['name'] ?? ''}',
                                        style: AppText.bodyMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (customIf(client['phone1']))
                                        Text(
                                          '${client['phone1']}',
                                          style: AppText.tabular(AppText.small),
                                        ),
                                    ],
                                  ),
                                ),
                                if (customIf(client['comment']))
                                  Flexible(
                                    child: Text(
                                      '${client['comment']}',
                                      style: AppText.small,
                                      textAlign: TextAlign.right,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
