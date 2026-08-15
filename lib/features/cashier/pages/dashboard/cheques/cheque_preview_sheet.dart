import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_mdokon/core/network/api.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/models/printer_model.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Что кассир выбрал в превью чека — обрабатывает вызывающий экран.
enum ChequePreviewAction { details, refund }

/// Статус чека одной строкой: цвет подложки, цвет текста и подпись.
/// Общий для карточки в списке и для превью — считаем по одним правилам.
(Color, Color, String) chequeStatusStyle(BuildContext context, Map cheque) {
  final returned = customNumber(cheque['returned']).round();
  final onCredit = customNumber(cheque['clientAmount']) > 0;

  return switch ((returned, onCredit)) {
    (2, _) => (AppColors.dangerSoft, AppColors.dangerText, context.tr('return')),
    (1, _) => (AppColors.warningSoft, AppColors.warningText, context.tr('partial_return')),
    (_, true) => (AppColors.warningSoft, AppColors.warningText, context.tr('on_credit')),
    _ => (AppColors.successSoft, AppColors.successText, context.tr('paid')),
  };
}

/// Превью чека — первый шаг по тапу в списке.
///
/// Показывает позиции, оплату и итог, не уводя со списка: печать доступна
/// прямо отсюда, полный дубликат чека — по «Подробнее о чеке».
/// Шапку рисуем сразу по данным строки списка, позиции догружаем запросом.
class ChequePreviewSheet extends StatefulWidget {
  /// Строка списка: номер, дата, статус и сумма уже известны.
  final Map cheque;
  final String number;
  final double total;

  const ChequePreviewSheet({
    super.key,
    required this.cheque,
    required this.number,
    required this.total,
  });

  @override
  State<ChequePreviewSheet> createState() => _ChequePreviewSheetState();
}

class _ChequePreviewSheetState extends State<ChequePreviewSheet> {
  Map? full;
  List items = [];
  List transactions = [];
  bool loading = true;
  bool printing = false;

  @override
  void initState() {
    super.initState();
    getCheque();
  }

  Future<void> getCheque() async {
    final response = await get('/services/desktop/api/cheque-byId-v2/${widget.cheque['id']}');
    if (!mounted) return;

    setState(() {
      if (httpOk(response) && response is Map) {
        full = response;
        items = response['itemsList'] ?? [];
        transactions = response['transactionsList'] ?? [];
      }
      loading = false;
    });
  }

  /// К оплате: сумма чека за вычетом скидки. Пока чек не догрузился —
  /// показываем итог из списка, он посчитан по тем же правилам.
  double get _total {
    final cheque = full;
    if (cheque == null) return widget.total;
    return customNumber(cheque['totalPrice']) -
        (customNumber(cheque['totalPrice']) * customNumber(cheque['discount'])) / 100;
  }

  String get _currency =>
      customNumber(widget.cheque['saleCurrencyId']) == 2 ? 'USD' : context.tr('sum');

  String get _time {
    final unixTime = widget.cheque['chequeDate'];
    if (unixTime == null) return '';
    return DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(unixTime));
  }

  /// Возврат уже оформленного возврата не предлагаем.
  bool get _refundable => customNumber(widget.cheque['returned']).round() != 2;

  Future<void> _print() async {
    final cheque = full;
    if (cheque == null || printing) return;

    setState(() => printing = true);
    await Provider.of<PrinterModel>(context, listen: false).printFullCheque(cheque, items);
    if (mounted) setState(() => printing = false);
  }

  @override
  Widget build(BuildContext context) {
    final (_, statusColor, statusLabel) = chequeStatusStyle(context, widget.cheque);

    // Чек может быть на два десятка позиций — выше 80% свободной высоты лист
    // не растёт, список внутри скроллится. Клавиатуры тут нет, но лист умеет
    // открываться поверх неё — считаем предел от незанятой части экрана.
    final media = MediaQuery.of(context);
    final maxHeight = (media.size.height - media.viewInsets.bottom) * 0.8;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${context.tr('cheque')} №${widget.number}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.tabular(AppText.h2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [_time, statusLabel].where((e) => e.isNotEmpty).join(' · '),
                      style: AppText.tabular(AppText.small).copyWith(color: statusColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.gap8),
              AppIconButton(
                icon: Icons.close,
                foreground: AppColors.textSecondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gap16),
          // Позиций может быть много — скроллим тело, кнопки остаются на месте.
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loading)
                    // Column растягивает детей по ширине — спиннер без Center
                    // разъезжается на весь лист.
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppDimens.gap24),
                      child: Center(child: AppLoader()),
                    )
                  else ...[
                    for (final item in items) ...[
                      _ItemRow(item: item, currency: _currency),
                      const SizedBox(height: AppDimens.gap8),
                    ],
                    for (final transaction in transactions)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${transaction['paymentTypeName'] ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.secondary,
                              ),
                            ),
                            const SizedBox(width: AppDimens.gap8),
                            Text(
                              '${formatMoney(transaction['amountIn'])} $_currency',
                              style: AppText.tabular(AppText.secondary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimens.gap12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: AppSectionLabel('${context.tr('total')} · $statusLabel')),
              const SizedBox(width: AppDimens.gap8),
              Text('${formatMoney(_total)} $_currency', style: AppText.amount),
            ],
          ),
          const SizedBox(height: AppDimens.gap12),
          AppButton(
            label: context.tr('cheque_details'),
            variant: AppButtonVariant.soft,
            size: AppButtonSize.medium,
            icon: Icons.receipt_long,
            trailingIcon: Icons.chevron_right,
            pill: false,
            onPressed: () => Navigator.of(context).pop(ChequePreviewAction.details),
          ),
          const SizedBox(height: AppDimens.gap8),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: context.tr('PRINT'),
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.medium,
                  loading: printing,
                  onPressed: loading ? null : _print,
                ),
              ),
              if (_refundable) ...[
                const SizedBox(width: AppDimens.gap8),
                Expanded(
                  child: AppButton(
                    label: context.tr('RETURN'),
                    variant: AppButtonVariant.danger,
                    size: AppButtonSize.medium,
                    onPressed: () => Navigator.of(context).pop(ChequePreviewAction.refund),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Позиция чека: название сверху, расчёт «цена × кол-во» — подписью.
class _ItemRow extends StatelessWidget {
  final Map item;
  final String currency;

  const _ItemRow({required this.item, required this.currency});

  @override
  Widget build(BuildContext context) {
    final returned = customNumber(item['returned']) > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${item['productName'] ?? ''}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyMedium.copyWith(
                  decoration: returned ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${formatMoney(item['salePrice'])} × ${formatMoney(item['quantity'])}',
                style: AppText.tabular(AppText.small),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimens.gap8),
        Text(
          '${formatMoney(item['totalPrice'])} $currency',
          style: AppText.price.copyWith(
            decoration: returned ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }
}
