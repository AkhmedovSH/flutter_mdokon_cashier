import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';

import 'package:flutter_mdokon/core/network/api.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/models/dashboard_model.dart';
import 'package:flutter_mdokon/features/cashier/models/printer_model.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/cheques/cheque_preview_sheet.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Дубликат чека — полный разбор одной продажи.
///
/// Вместо ленты «как на бумаге» — карточки: реквизиты точки, реквизиты чека,
/// позиции и итоги. Печать и возврат вынесены в закреплённую нижнюю панель,
/// чтобы до них не нужно было доскроллить длинный чек.
class ChequeDetail extends StatefulWidget {
  final String id;

  const ChequeDetail({
    super.key,
    required this.id,
  });

  @override
  State<ChequeDetail> createState() => _ChequeDetailState();
}

class _ChequeDetailState extends State<ChequeDetail> {
  final GetStorage storage = GetStorage();

  Map cheque = {};
  Map cashbox = {};
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
    final response = await get('/services/desktop/api/cheque-byId-v2/${widget.id}');
    if (!mounted) return;

    setState(() {
      final stored = storage.read('cashbox');
      cashbox = stored is Map ? stored : {};

      if (httpOk(response) && response is Map) {
        cheque = response;
        items = response['itemsList'] ?? [];
        transactions = response['transactionsList'] ?? [];
      }
      loading = false;
    });
  }

  // --- Расчёты -----------------------------------------------------------

  /// Скидка в чеке хранится процентом — в деньги переводим здесь, чтобы
  /// и строка «Сумма скидки», и итог считались из одного места.
  double get _discount =>
      customNumber(cheque['totalPrice']) * customNumber(cheque['discount']) / 100;

  double get _toPay => customNumber(cheque['totalPrice']) - _discount;

  String get _currency => customNumber(cheque['saleCurrencyId']) == 2 ? 'USD' : context.tr('sum');

  String get _number => '${cheque['chequeNumber'] ?? widget.id}';

  /// Возврат уже оформленного возврата не предлагаем.
  bool get _refundable =>
      cheque.isNotEmpty && cheque['status'] != 2 && customNumber(cheque['returned']).round() != 2;

  // --- Действия ----------------------------------------------------------

  Future<void> _print() async {
    if (cheque.isEmpty || printing) return;

    setState(() => printing = true);
    await Provider.of<PrinterModel>(context, listen: false).printFullCheque(cheque, items);
    if (mounted) setState(() => printing = false);
  }

  void _refund() {
    Provider.of<DashboardModel>(context, listen: false).setCurrentCheque(cheque);
    // 3 — вкладка «Возврат»: она подхватит переданный чек и откроет его позиции.
    Provider.of<DashboardModel>(context, listen: false).setCurrentIndex(3);
    context.go('/cashier');
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/cashier');
    }
  }

  // --- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: loading
                ? const Center(child: AppLoader())
                : cheque.isEmpty
                    ? AppEmptyState(
                        icon: Icons.receipt_long,
                        title: context.tr('NOT_FOUND'),
                      )
                    : ContentBox(child: _content()),
          ),
        ],
      ),
      bottomNavigationBar: loading || cheque.isEmpty ? null : _actions(),
    );
  }

  /// Шапка: возврат назад, номер чека и его статус одной строкой.
  Widget _header() {
    final (_, statusColor, statusLabel) = cheque.isEmpty
        ? (AppColors.canvas, AppColors.textSecondary, '')
        : chequeStatusStyle(context, cheque);

    final meta = [
      if (cheque['chequeDate'] != null) formatUnixTime(cheque['chequeDate']),
      statusLabel,
    ].where((e) => e.isNotEmpty).join(' · ');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.surface,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gap8,
              AppDimens.gap8,
              AppDimens.gutter,
              AppDimens.gap12,
            ),
            child: Row(
              children: [
                AppIconButton(
                  icon: Icons.arrow_back,
                  foreground: AppColors.textPrimary,
                  background: Colors.transparent,
                  onPressed: _back,
                ),
                const SizedBox(width: AppDimens.gap4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${context.tr('cheque')} №$_number',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.tabular(AppText.h1).copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.tabular(AppText.small).copyWith(color: statusColor),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        AppDimens.gap12,
        AppDimens.gutter,
        AppDimens.gap24,
      ),
      children: [
        _shopCard(),
        const SizedBox(height: AppDimens.gap12),
        _infoCard(),
        const SizedBox(height: AppDimens.gap16),
        AppSectionLabel('${context.tr('products')} · ${items.length} ${context.tr('positions_short')}'),
        const SizedBox(height: AppDimens.gap8),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: AppDimens.gap8),
          _ItemCard(index: i + 1, item: items[i], currency: _currency),
        ],
        const SizedBox(height: AppDimens.gap16),
        _totalsCard(),
        if (customIf(cheque['barcode'])) ...[
          const SizedBox(height: AppDimens.gap12),
          _barcodeCard(),
        ],
        const SizedBox(height: AppDimens.gap16),
        Center(
          child: Text(
            '${context.tr('thank_you_for_your_purchase')}!',
            style: AppText.secondary,
          ),
        ),
      ],
    );
  }

  /// Реквизиты торговой точки — шапка бумажного чека.
  Widget _shopCard() {
    final phone = '${cashbox['posPhone'] ?? ''}'.trim();
    final address = '${cashbox['posAddress'] ?? ''}'.trim();

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap16, vertical: AppDimens.gap16),
      child: Column(
        children: [
          Text(
            '${cashbox['posName'] ?? ''}',
            textAlign: TextAlign.center,
            style: AppText.h2,
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              formatPhone(phone),
              textAlign: TextAlign.center,
              style: AppText.tabular(AppText.secondary),
            ),
          ],
          if (address.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(address, textAlign: TextAlign.center, style: AppText.secondary),
          ],
        ],
      ),
    );
  }

  /// Реквизиты чека: ИНН, кассир, идентификатор, тип, дата и смена.
  Widget _infoCard() {
    final inn = '${cheque['tin'] ?? cashbox['tin'] ?? cashbox['inn'] ?? ''}'.trim();
    final isReturn = customNumber(cheque['returned']).round() == 2;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap16, vertical: 6),
      child: Column(
        children: [
          if (inn.isNotEmpty) _InfoRow(label: context.tr('inn'), value: inn),
          if (customIf(cheque['cashierName']))
            _InfoRow(label: context.tr('cashier'), value: '${cheque['cashierName']}', tabular: false),
          if (customIf(cheque['transactionId']))
            _InfoRow(label: '${context.tr('cheque')} ID', value: '${cheque['transactionId']}'),
          _InfoRow(
            label: context.tr('cheque_type'),
            value: context.tr(isReturn ? 'return' : 'sale'),
            tabular: false,
          ),
          if (cheque['chequeDate'] != null)
            _InfoRow(label: context.tr('date'), value: formatUnixTime(cheque['chequeDate'])),
          if (customIf(cheque['shiftNumber']))
            _InfoRow(label: context.tr('shift'), value: '${cheque['shiftNumber']}'),
        ],
      ),
    );
  }

  /// Итоги: сначала расчёт, затем «К оплате», ниже — чем платили.
  Widget _totalsCard() {
    final change = customNumber(cheque['change']);
    final debt = customNumber(cheque['clientAmount']);
    final client = '${cheque['clientName'] ?? ''}'.trim();
    final loyaltyClient = '${cheque['loyaltyClientName'] ?? ''}'.trim();

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap16, vertical: 6),
      child: Column(
        children: [
          _InfoRow(
            label: context.tr('sale_amount'),
            value: formatMoney(cheque['totalPrice']),
          ),
          if (cheque['totalVatAmount'] != null)
            _InfoRow(
              label: context.tr('vat_amount'),
              value: formatMoney(cheque['totalVatAmount']),
            ),
          _InfoRow(
            label: context.tr('discount_amount'),
            value: formatMoney(_discount),
          ),
          const _RowDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimens.gap8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: AppSectionLabel(context.tr('to_pay'))),
                const SizedBox(width: AppDimens.gap8),
                Text('${formatMoney(_toPay)} $_currency', style: AppText.amount),
              ],
            ),
          ),
          const _RowDivider(),
          _InfoRow(label: context.tr('paid'), value: formatMoney(cheque['paid'])),
          if (change > 0) _InfoRow(label: context.tr('change'), value: formatMoney(change)),
          for (final transaction in transactions)
            _InfoRow(
              label: '${transaction['paymentTypeName'] ?? context.tr('payment')}',
              value: formatMoney(transaction['amountIn']),
              muted: true,
            ),
          if (debt > 0) ...[
            const _RowDivider(),
            _InfoRow(
              label: context.tr('AMOUNT_OF_DEBT'),
              value: formatMoney(debt),
              valueColor: AppColors.warningText,
            ),
            if (client.isNotEmpty)
              _InfoRow(label: context.tr('debtor'), value: client, tabular: false),
          ] else if (client.isNotEmpty)
            _InfoRow(label: context.tr('client'), value: client, tabular: false),
          if (loyaltyClient.isNotEmpty)
            _InfoRow(label: context.tr('loyalty'), value: loyaltyClient, tabular: false),
        ],
      ),
    );
  }

  Widget _barcodeCard() {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap16, vertical: AppDimens.gap16),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: SfBarcodeGenerator(
              value: '${cheque['barcode']}',
              showValue: false,
              barColor: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.gap8),
          Text(
            '${cheque['barcode']}',
            style: AppText.tabular(AppText.small),
          ),
        ],
      ),
    );
  }

  /// Закреплённая панель действий — печать и возврат всегда под рукой.
  Widget _actions() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.gutter,
            AppDimens.gap12,
            AppDimens.gutter,
            AppDimens.gap12,
          ),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: context.tr('PRINT'),
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.medium,
                  icon: Icons.print_outlined,
                  loading: printing,
                  onPressed: _print,
                ),
              ),
              if (_refundable) ...[
                const SizedBox(width: AppDimens.gap8),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    label: context.tr('make_return'),
                    variant: AppButtonVariant.dangerSolid,
                    size: AppButtonSize.medium,
                    onPressed: _refund,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Позиция чека: номер и название сверху, расчёт и НДС — подписью.
/// Возвращённую позицию зачёркиваем и подписываем количеством возврата.
class _ItemCard extends StatelessWidget {
  final int index;
  final Map item;
  final String currency;

  const _ItemCard({required this.index, required this.item, required this.currency});

  @override
  Widget build(BuildContext context) {
    final returned = customNumber(item['returned']) > 0;
    final returnedQuantity = customNumber(item['returnedQuantity']);
    final vat = customNumber(item['vat']);

    final strike = returned ? TextDecoration.lineThrough : null;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppDimens.gap12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '$index. ${item['productName'] ?? ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyMedium.copyWith(decoration: strike),
                ),
              ),
              const SizedBox(width: AppDimens.gap8),
              Text(
                '${formatMoney(item['totalPrice'])} $currency',
                style: AppText.price.copyWith(decoration: strike),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatMoney(item['quantity'])} × ${formatMoney(item['salePrice'])}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tabular(AppText.small),
                ),
              ),
              const SizedBox(width: AppDimens.gap8),
              Text(
                '${context.tr('VAT')} ${formatMoney(vat)}%',
                style: AppText.tabular(AppText.small),
              ),
            ],
          ),
          if (returnedQuantity > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${context.tr('return')} · ${formatMoney(returnedQuantity)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.tabular(AppText.small).copyWith(color: AppColors.dangerText),
                  ),
                ),
                const SizedBox(width: AppDimens.gap8),
                Text(
                  '${formatMoney(item['returnedPrice'])} $currency',
                  style: AppText.tabular(AppText.small).copyWith(color: AppColors.dangerText),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Строка «подпись — значение» в карточках реквизитов и итогов.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  /// Суммы и идентификаторы — моноширинными цифрами, имена — обычными.
  final bool tabular;
  final bool muted;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.tabular = true,
    this.muted = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = (muted ? AppText.secondary : AppText.bodyMedium).copyWith(
      color: valueColor ?? (muted ? AppColors.textSecondary : AppColors.textPrimary),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.gap8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.secondary),
          const SizedBox(width: AppDimens.gap12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: tabular ? AppText.tabular(style) : style,
            ),
          ),
        ],
      ),
    );
  }
}

/// Разделитель между группами строк внутри карточки.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: AppColors.divider);
  }
}
