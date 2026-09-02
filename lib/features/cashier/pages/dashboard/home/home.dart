import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

import 'package:flutter_mdokon/core/state/settings_model.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/models/cashbox_model.dart';
import 'package:flutter_mdokon/features/cashier/data/quick_rail_repository.dart';
import 'package:flutter_mdokon/features/cashier/domain/hotkeys.dart';
import 'package:flutter_mdokon/features/cashier/domain/product_search.dart';
import 'package:flutter_mdokon/features/cashier/domain/postponed_cheque.dart';
import 'package:flutter_mdokon/features/cashier/models/dashboard_model.dart';
import 'package:flutter_mdokon/features/cashier/models/sale_model.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/home/sale_sheets.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/home/widgets/cart_line_tile.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/home/widgets/hotkeys_panel.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/home/widgets/marking_codes_sheet.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/home/widgets/quick_rail.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/home/widgets/sale_header.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/home/widgets/sale_summary_bar.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/home/widgets/sale_tabs_bar.dart';
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
  final QuickRailRepository _quickRail = const QuickRailRepository();
  final FocusNode _hotkeyFocus = FocusNode(debugLabel: 'cashier-hotkeys');

  /// Набранное на внешней клавиатуре число, ждущее клавишу операции («2» в «2+»).
  String _hotkeyBuffer = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _hotkeyFocus.dispose();
    super.dispose();
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

  /// Каталог — вкладка нижней навигации. Скидка добавлению позиций больше не
  /// мешает: она хранится параметрами и пересчитывается после каждого
  /// изменения корзины.
  void _openCatalog() => context.read<DashboardModel>().setCurrentIndex(1);

  /// Быстрая операция над выбранной позицией: сначала спрашиваем значение
  /// отдельным листом, потом применяем операцию.
  Future<void> _applyShortcut(SaleShortcut shortcut) async {
    if (!_ensureShortcutAllowed(shortcut)) return;

    final value = await SaleSheets.shortcutValue(context, shortcut);
    if (value == null || !mounted) return;

    final model = _model;
    model.setShortcutValue(value);
    final needsUnitDialog = model.applyShortcut(shortcut);
    FocusManager.instance.primaryFocus?.unfocus();
    if (needsUnitDialog && mounted) await SaleSheets.unit(context, model);
  }

  /// Смена цены и скидки закрыты ролями. Проверяем на обоих входах: меню уже
  /// отфильтровано, но клавиатура на планшете зовёт операцию напрямую.
  bool _ensureShortcutAllowed(SaleShortcut shortcut) {
    if (shortcut.allowed) return true;
    showDangerToast(context.tr('no_role_permission'));
    return false;
  }

  // --- Горячие клавиши (планшет с внешней клавиатурой) --------------------

  /// Имя нажатой клавиши для [resolveHotkey].
  ///
  /// У функциональных клавиш `character` пустой, у цифр и знаков — наоборот,
  /// именно он учитывает раскладку, поэтому смотрим оба поля.
  String _keyLabel(KeyEvent event) {
    final named = <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.f5: 'F5',
      LogicalKeyboardKey.f6: 'F6',
      LogicalKeyboardKey.f7: 'F7',
      LogicalKeyboardKey.f9: 'F9',
      LogicalKeyboardKey.backspace: 'Backspace',
      LogicalKeyboardKey.escape: 'Escape',
    };
    return named[event.logicalKey] ?? (event.character ?? '');
  }

  KeyEventResult _onHotkey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    return _handleKey(_keyLabel(event)) ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  /// Нажатие клавиши — с внешней клавиатуры или с экранного блока боковой
  /// колонки. Путь один: иначе раскладка разъехалась бы на двух обработчиках.
  bool _handleKey(String key) {
    final command = resolveHotkey(key, buffer: _hotkeyBuffer);
    switch (command.action) {
      case HotkeyAction.none:
        return false;
      case HotkeyAction.append:
        setState(() => _hotkeyBuffer = appendToHotkeyBuffer(_hotkeyBuffer, command.symbol!));
      case HotkeyAction.backspace:
        setState(() => _hotkeyBuffer = _hotkeyBuffer.substring(0, _hotkeyBuffer.length - 1));
      case HotkeyAction.clearInput:
        setState(() => _hotkeyBuffer = '');
      case HotkeyAction.clearCheque:
        setState(() => _hotkeyBuffer = '');
        _confirmClear();
      case HotkeyAction.shortcut:
        _runHotkeyShortcut(command.shortcut!);
    }
    return true;
  }

  /// Операция с клавиатуры: значение уже набрано, лист ввода не открываем.
  Future<void> _runHotkeyShortcut(SaleShortcut shortcut) async {
    if (!_ensureShortcutAllowed(shortcut)) {
      setState(() => _hotkeyBuffer = '');
      return;
    }

    final model = _model;
    model.setShortcutValue(_hotkeyBuffer);
    setState(() => _hotkeyBuffer = '');

    final needsUnitDialog = model.applyShortcut(shortcut);
    if (needsUnitDialog && mounted) await SaleSheets.unit(context, model);
  }

  // --- Боковая колонка быстрого выбора -----------------------------------

  /// Товар из колонки: одна штука в чек по штрих-коду.
  ///
  /// Каталог для этого не открываем — колонка тем и нужна, что кассир не
  /// уходит с экрана продажи.
  Future<void> _addByBarcode(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return;

    final model = _model;
    // Скидка на чек считается по набранным позициям: добавление после неё
    // увело бы итог мимо скидки. Тот же запрет стоит в каталоге.
    if (model.discountPercent > 0) {
      showDangerToast(context.tr('discount_has_been_applied'));
      return;
    }

    final rows = await _quickRail.search(
      posId: model.cashbox['posId'],
      currencyId: model.data['currencyId'],
      query: code,
    );
    if (!mounted) return;

    // Товар без остатка добавляем только там, где продажа в минус разрешена.
    final available = rows
        .where((row) => model.saleMinus || customNumber(row['balance']) > 0)
        .toList();
    final matched = applyExactSearch(available, code);
    if (matched.isEmpty) {
      showDangerToast(context.tr('product_out_of_stock'));
      return;
    }

    final product = Map<String, dynamic>.from(matched.first as Map);
    product['quantity'] = 1;
    final needsUnitDialog = model.addScannedProducts([product]);
    if (needsUnitDialog && mounted) await SaleSheets.unit(context, model);
  }

  /// Клавиша экранного цифрового блока колонки.
  void _onRailKey(String key) => _handleKey(key);

  /// «Добавить в чек» на экранной клавиатуре: набранное — это код товара.
  Future<void> _submitBuffer() async {
    final code = _hotkeyBuffer;
    if (code.isEmpty) return;
    setState(() => _hotkeyBuffer = '');
    await _addByBarcode(code);
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
      case SaleAction.postponeSave:
        await _postpone();
      case SaleAction.postponeOpen:
        final store = SaleSheets.postponeStoreOf(context);
        if (store != null) await SaleSheets.postponedList(context, model, store);
      case SaleAction.chequeFromCloud:
        await SaleSheets.postponedList(context, model, PostponeStore.cloud);
      case SaleAction.supplierSettlement:
        await SaleSheets.suppliers(context, model);
    }
  }

  /// Отложить чек — туда, куда велят настройки.
  ///
  /// Набранный чек уходит из корзины: с этого момента он живёт в списке
  /// отложенных, а не на экране.
  Future<void> _postpone() async {
    final store = SaleSheets.postponeStoreOf(context);
    if (store == null) return;
    final ok = await _model.postponeCheque(store);
    if (ok && mounted) showSuccessToast(context.tr('cheque_postponed'));
  }

  /// Закрыть вкладку. Набранный чек пропадает без следа — в отличие от
  /// отложенного, вкладку никуда не сохранить, поэтому спрашиваем всегда,
  /// независимо от настройки подтверждений: это не «очистить чек», а
  /// «выбросить чек, о котором кассир мог забыть».
  Future<void> _closeTab(int id) async {
    final model = _model;
    final tab = model.tabs.tabs.firstWhere((e) => e.id == id);
    if (!tab.isEmpty) {
      final ok = await AppModal.confirm(
        context,
        title: context.tr('are_you_sure_you_want_to_remove_all_products'),
        confirmLabel: context.tr('close'),
        cancelLabel: context.tr('cancel'),
        tone: AppModalTone.danger,
      );
      if (!ok || !mounted) return;
    }
    model.closeTab(id);
  }

  Future<void> _confirmClear() async {
    // Настройка снимает подтверждение целиком: на потоке кассир чистит чек
    // десятки раз за смену, и лишний вопрос только мешает.
    if (!context.read<SettingsModel>().showConfirmModalDeleteAllItems) {
      _model.clearCheque();
      return;
    }

    final ok = await AppModal.confirm(
      context,
      title: context.tr('are_you_sure_you_want_to_remove_all_products'),
      confirmLabel: context.tr('clear'),
      cancelLabel: context.tr('cancel'),
      tone: AppModalTone.danger,
    );
    if (ok) _model.clearCheque();
  }

  /// Спросить подтверждение удаления позиции, если оно включено в настройках.
  Future<bool> _confirmDeleteLine(Map item) async {
    if (!context.read<SettingsModel>().showConfirmModalDeleteItem) return true;

    return AppModal.confirm(
      context,
      title: context.tr('are_you_sure_you_want_to_delete_the_product'),
      text: '${item['productName'] ?? ''}',
      confirmLabel: context.tr('delete'),
      cancelLabel: context.tr('cancel'),
      tone: AppModalTone.danger,
    );
  }

  Future<void> _deleteLine(int index, Map item) async {
    if (await _confirmDeleteLine(item)) _model.deleteLine(index);
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

    // Горячие клавиши ловим только на планшете: внешняя клавиатура и сканер в
    // режиме клавиатуры бывают там, а на телефоне `Focus` только перехватывал
    // бы ввод у экранной клавиатуры.
    final screen = Scaffold(
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
          // Параллельные чеки — только планшет: на телефоне нет ни ширины,
          // ни сценария «два покупателя у одной кассы».
          if (layout.isTablet)
            SaleTabsBar(
              state: model.tabs,
              currency: model.currencyName,
              onSelect: model.switchTab,
              onClose: _closeTab,
              onAdd: model.addTab,
            ),
          if (layout.isTablet) _hotkeyBar(),
          Expanded(
            child: SideRailLayout(
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
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
                  ),
                  // Быстрый выбор — только там, где после чека и итогов
                  // остаётся ширина: на телефоне товар ищут через каталог.
                  if (layout.hasSideRail)
                    QuickRail(
                      buffer: _hotkeyBuffer,
                      onAddBarcode: _addByBarcode,
                      onKey: _onRailKey,
                      onSubmit: _submitBuffer,
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

    if (!layout.isTablet) return screen;

    return Focus(
      focusNode: _hotkeyFocus,
      autofocus: true,
      onKeyEvent: _onHotkey,
      child: screen,
    );
  }

  /// Строка горячих клавиш: что уже набрано на внешней клавиатуре и вход в
  /// подсказку. Без неё набранное число нигде не видно — кассир жал бы `+`
  /// вслепую.
  Widget _hotkeyBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.layout.gutter,
        vertical: AppDimens.gap4,
      ),
      child: Row(
        children: [
          Icon(UniconsLine.keyboard, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppDimens.gap8),
          Expanded(
            child: Text(
              _hotkeyBuffer.isEmpty ? context.tr('hotkeys_hint') : _hotkeyBuffer,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _hotkeyBuffer.isEmpty
                  ? AppText.secondary
                  : AppText.tabular(AppText.secondaryBold).copyWith(color: AppColors.primary),
            ),
          ),
          AppIconButton(
            icon: UniconsLine.question_circle,
            background: AppColors.canvas,
            foreground: AppColors.textSecondary,
            size: AppDimens.tapTarget,
            iconSize: 18,
            onPressed: () => HotkeysPanel.show(context),
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

    // Кассир смотрит на сканер, а не на экран: строка сверху говорит, что
    // именно попало в чек последним, не заставляя искать её в списке.
    final showLast = context.select<SettingsModel, bool>((s) => s.showLastScannedProduct);

    final list = ListView.separated(
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
            dismissible: DismissiblePane(
              // Свайп в сторону — жест необратимый и лёгкий на случайное
              // срабатывание, поэтому подтверждение спрашиваем до удаления.
              confirmDismiss: () => _confirmDeleteLine(item),
              onDismissed: () => model.deleteLine(index),
            ),
            children: [
              SlidableAction(
                onPressed: (_) => _deleteLine(index, item),
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
            onMarkingCodes: (scan) => showMarkingCodesSheet(
              context,
              model,
              index,
              scanImmediately: scan,
            ),
          ),
        );
      },
    );

    if (!showLast) return list;

    return Column(
      children: [
        _LastScannedBar(item: model.items.last as Map, currency: model.currencyName),
        Expanded(child: list),
      ],
    );
  }
}

/// Строка «последний товар»: что и в каком количестве только что добавлено.
class _LastScannedBar extends StatelessWidget {
  final Map item;
  final String currency;

  const _LastScannedBar({required this.item, required this.currency});

  @override
  Widget build(BuildContext context) {
    final quantity = customNumber(item['quantity']);
    final sum = quantity * customNumber(item['salePrice']);

    return Container(
      width: double.infinity,
      color: AppColors.primarySoft,
      padding: EdgeInsets.symmetric(
        horizontal: context.layout.gutter,
        vertical: AppDimens.gap8,
      ),
      child: Row(
        children: [
          Icon(UniconsLine.qrcode_scan, size: 16, color: AppColors.primary),
          const SizedBox(width: AppDimens.gap8),
          Expanded(
            child: Text(
              '${item['productName'] ?? ''} × ${formatMoney(quantity)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.secondaryBold.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppDimens.gap8),
          Text(
            '${formatMoney(sum)} $currency',
            style: AppText.tabular(AppText.secondaryBold).copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
