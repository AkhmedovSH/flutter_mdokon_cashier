import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

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
  /// Оболочка уже показывает кассира и точку в своей шапке (верхняя навигация
  /// планшета). Тогда фиолетовую шапку продажи здесь не рисуем — иначе имя
  /// кассира дублируется. У агента своя оболочка без такой шапки.
  final bool hasShellHeader;

  const CashierHome({super.key, this.hasShellHeader = false});

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

  /// Каталог — вкладка нижней навигации. Скидка на чек блокирует добавление
  /// позиций, поэтому туда же и не пускаем.
  void _openCatalog() {
    if (_model.discountPercent > 0) {
      showDangerToast(context.tr('discount_has_been_applied'));
      return;
    }
    context.read<DashboardModel>().setCurrentIndex(1);
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
    final layout = context.layout;

    final payLabel = model.isAgent ? context.tr('send_to_cashbox') : context.tr('sell');
    final onPay = model.isEmpty ? null : (model.isAgent ? _sendToCashbox : _openPayment);
    // На пустом чеке меню нечего показывать — кроме агента, у которого
    // остаётся выбор клиента.
    final onMore = model.isEmpty && !model.isAgent ? null : _openChequeActions;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          // Кто работает на кассе, на планшете уже написано в верхней
          // навигации — здесь остаётся узкая панель самого чека.
          if (widget.hasShellHeader && layout.useTopNav)
            _chequeToolbar(model)
          else
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
            child: SideRailLayout(
              body: Stack(
                children: [
                  model.isEmpty ? _empty(context) : _cart(model),
                  Positioned(
                    right: layout.gutter,
                    bottom: layout.gutter,
                    child: AppIconButton.floating(
                      icon: UniconsLine.qrcode_scan,
                      tooltip: context.tr('search'),
                      onPressed: _openCatalog,
                    ),
                  ),
                ],
              ),
              // Широкий экран: итоги и оплата стоят колонкой справа и всегда
              // на виду — чек из-за них не прокручивается.
              rail: SaleSummaryPanel(
                lineCount: model.lineCount,
                subtotal: model.subtotal,
                discountPercent: model.discountPercent,
                discountSum: model.discountSum,
                total: model.totalPrice,
                currency: model.currencyName,
                payLabel: payLabel,
                busy: model.busy,
                onPay: onPay,
                onMore: onMore,
                onCashierActions: _openCashierActions,
              ),
              bottom: SaleSummaryBar(
                lineCount: model.lineCount,
                subtotal: model.subtotal,
                discountPercent: model.discountPercent,
                discountSum: model.discountSum,
                total: model.totalPrice,
                currency: model.currencyName,
                payLabel: payLabel,
                busy: model.busy,
                onPay: onPay,
                onMore: onMore,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Панель чека на планшете: сколько позиций набрано и меню кассы.
  Widget _chequeToolbar(SaleModel model) {
    final layout = context.layout;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.symmetric(horizontal: layout.gutter, vertical: AppDimens.gap8),
      child: Row(
        children: [
          Text(context.tr('cheque'), style: AppText.h1),
          const SizedBox(width: AppDimens.gap12),
          Text(
            '${model.lineCount} ${context.tr('pieces_short')}',
            style: AppText.tabular(AppText.secondary),
          ),
          const Spacer(),
          // На широком экране колонка справа уже держит меню чека —
          // здесь оставляем только настройки кассы.
          if (!layout.hasSideRail)
            AppIconButton(
              icon: Icons.more_horiz,
              background: AppColors.canvas,
              foreground: AppColors.textSecondary,
              size: layout.tapTarget,
              iconSize: 22,
              onPressed: _openCashierActions,
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
    final layout = context.layout;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        layout.gutter,
        AppDimens.gap12,
        layout.gutter,
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
