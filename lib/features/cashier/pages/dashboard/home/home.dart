import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

import 'package:flutter_mdokon/core/state/data_model.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/models/cashbox_model.dart';
import 'package:flutter_mdokon/features/cashier/models/dashboard_model.dart';
import 'package:flutter_mdokon/features/cashier/models/sale_model.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/home/sale_sheets.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/home/widgets/cart_line_tile.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/home/widgets/sale_header.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/home/widgets/sale_summary_bar.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Экран продажи. Вся логика чека живёт в [SaleModel] — страница только
/// рисует состояние, открывает листы и выполняет переходы по маршрутам.
class CashierHome extends StatefulWidget {
  const CashierHome({super.key});

  @override
  State<CashierHome> createState() => _CashierHomeState();
}

class _CashierHomeState extends State<CashierHome> {
  final GetStorage _storage = GetStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  /// Инициализация кассы. Агенту может прийти чек на редактирование.
  Future<void> _init() async {
    if (!mounted) return;
    final dashboard = context.read<DashboardModel>();
    final returned = dashboard.returnCheque;

    Map? cheque;
    if (returned.isNotEmpty && returned['cheque'] != null) {
      cheque = jsonDecode(returned['cheque']);
      dashboard.setCurrentCheque({});
    }

    await context.read<SaleModel>().init(returnCheque: cheque);
  }

  SaleModel get _model => context.read<SaleModel>();

  // --- Действия ----------------------------------------------------------

  /// Каталог товаров. Скидка на чек блокирует добавление позиций.
  Future<void> _openCatalog() async {
    final model = _model;
    if (model.discountPercent > 0) {
      showDangerToast(context.tr('discount_has_been_applied'));
      return;
    }

    await context.push('/cashier/search', extra: {
      'activePrice': model.data['activePrice'],
      'currencyId': model.data['currencyId'],
      'currencyName': model.data['currencyName'],
    });
    if (!mounted) return;

    final dataModel = context.read<DataModel>();
    final products = List.from(dataModel.currentProductList);
    dataModel.setProductList([]);
    if (products.isEmpty) return;

    if (model.addScannedProducts(products)) {
      await SaleSheets.unit(context, model);
    }
  }

  /// Быстрая операция над выбранной позицией: сначала спрашиваем значение
  /// отдельным листом, потом применяем операцию.
  Future<void> _applyShortcut(SaleShortcut shortcut) async {
    final value = await SaleSheets.shortcutValue(context, shortcut);
    if (value == null || !mounted) return;

    final model = _model;
    model.setShortcutValue(value);
    final needsUnitDialog = model.applyShortcut(shortcut);
    FocusManager.instance.primaryFocus?.unfocus();
    if (needsUnitDialog && mounted) await SaleSheets.unit(context, model);
  }

  /// Переход к оплате. Возврат `true` из оплаты очищает чек.
  Future<void> _openPayment() async {
    final model = _model;
    if (model.isEmpty) return;

    context.read<CashboxModel>().init(model.data);
    final result = await context.push('/cashier/payment', extra: model.data);
    if (result == true) model.clearCheque();
  }

  Future<void> _sendToCashbox() async {
    final ok = await _model.sendToCashbox();
    if (ok && mounted) showSuccessToast(context.tr('success'));
  }

  /// Меню чека («…» в блоке итогов).
  Future<void> _openChequeActions() async {
    final action = await SaleSheets.chequeActions(context, _model);
    if (action == null || !mounted) return;

    // Операции над позицией сами спрашивают значение отдельным листом.
    if (action is SaleShortcut) {
      await _applyShortcut(action);
      return;
    }
    await _runAction(action as SaleAction);
  }

  /// Меню кассы («…» в шапке).
  Future<void> _openCashierActions() async {
    final action = await SaleSheets.cashierActions(context, _model);
    if (action == null || !mounted) return;
    await _runAction(action);
  }

  Future<void> _runAction(SaleAction action) async {
    final model = _model;
    switch (action) {
      case SaleAction.priceMode:
        await SaleSheets.priceMode(context, model);
      case SaleAction.currency:
        // Валюта чека меняется только на пустом чеке.
        if (!model.canChangeCurrency) {
          showDangerToast(context.tr('currency_can_be_changed_on_an_empty_cheque'));
          return;
        }
        model.toggleCurrency();
      case SaleAction.debtRepayment:
        await SaleSheets.debt(context, model);
      case SaleAction.expense:
        await SaleSheets.expense(context, model);
      case SaleAction.selectClient:
        await SaleSheets.selectClient(context, model);
      case SaleAction.createClient:
        await SaleSheets.createClient(context, model);
      case SaleAction.clearCheque:
        await _confirmClear();
    }
  }

  Future<void> _confirmClear() async {
    final ok = await AppModal.confirm(
      context,
      title: context.tr('are_you_sure_you_want_to_remove_all_products'),
      confirmLabel: context.tr('clear'),
      cancelLabel: context.tr('cancel'),
      tone: AppModalTone.danger,
    );
    if (ok) _model.clearCheque();
  }

  // --- Вёрстка -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final model = context.watch<SaleModel>();
    final user = _storage.read('user') ?? {};

    return Scaffold(
      backgroundColor: AppColors.canvas,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          SaleHeader(
            name: '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim().isEmpty
                ? '${user['login'] ?? ''}'
                : '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim(),
            meta: [
              if (customIf(model.cashbox['posId'])) 'POS ID: ${model.cashbox['posId']}',
              if (customIf(model.cashbox['posName'])) '${model.cashbox['posName']}',
              if (customIf(model.cashbox['cashboxName'])) '${model.cashbox['cashboxName']}',
            ].join(' · '),
            onActionsTap: _openCashierActions,
          ),
          Expanded(
            child: Stack(
              children: [
                model.isEmpty ? _empty(context) : _cart(model),
                Positioned(
                  right: AppDimens.gutter,
                  bottom: AppDimens.gutter,
                  child: AppIconButton.floating(
                    icon: UniconsLine.qrcode_scan,
                    tooltip: context.tr('search'),
                    onPressed: _openCatalog,
                  ),
                ),
              ],
            ),
          ),
          SaleSummaryBar(
            lineCount: model.lineCount,
            subtotal: model.subtotal,
            discountPercent: model.discountPercent,
            discountSum: model.discountSum,
            total: model.totalPrice,
            currency: model.currencyName,
            payLabel: model.isAgent ? context.tr('send_to_cashbox') : context.tr('sell'),
            busy: model.busy,
            onPay: model.isEmpty ? null : (model.isAgent ? _sendToCashbox : _openPayment),
            onMore: _openChequeActions,
          ),
        ],
      ),
    );
  }

  /// Пустой чек: подсказка про сканер и вход в каталог.
  Widget _empty(BuildContext context) {
    return AppEmptyState(
      icon: UniconsLine.shopping_cart,
      title: context.tr('cheque_is_empty'),
      text: context.tr('scan_barcode_from_product_packaging_or_enter_it_manually'),
      action: AppButton.soft(
        label: context.tr('open_catalog'),
        onPressed: _openCatalog,
      ),
    );
  }

  /// Панель быстрых операций и список позиций (новые сверху).
  Widget _cart(SaleModel model) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        AppDimens.gap12,
        AppDimens.gutter,
        96,
      ),
      itemCount: model.lineCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimens.gap8),
      itemBuilder: (context, position) {
        // Свежая позиция — первой в списке.
        final index = model.lineCount - 1 - position;
        final item = model.items[index] as Map;

        return Slidable(
          key: ValueKey('${item['balanceId']}_$index'),
          closeOnScroll: false,
          useTextDirection: false,
          enabled: checkRole('CASHBOX_DELETE_SCAN_ITEM'),
          endActionPane: ActionPane(
            motion: const StretchMotion(),
            extentRatio: 0.28,
            dismissible: DismissiblePane(onDismissed: () => model.deleteLine(index)),
            children: [
              SlidableAction(
                onPressed: (_) => model.deleteLine(index),
                backgroundColor: AppColors.dangerText,
                foregroundColor: AppColors.onPrimary,
                icon: UniconsLine.trash_alt,
                borderRadius: AppDimens.card,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          child: CartLineTile(
            index: index,
            item: item,
            currency: model.currencyName,
            onTap: () => model.selectLine(index),
            onQuantityChanged: (value) => model.setQuantity(index, value),
          ),
        );
      },
    );
  }
}
