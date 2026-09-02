import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

import 'package:flutter_mdokon/core/utils/logger.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/data/postponed_cheque_repository.dart';
import 'package:flutter_mdokon/features/cashier/data/sale_repository.dart';
import 'package:flutter_mdokon/features/cashier/data/supplier_debt_repository.dart';
import 'package:flutter_mdokon/features/cashier/domain/manual_discount.dart';
import 'package:flutter_mdokon/features/cashier/domain/postponed_cheque.dart';
import 'package:flutter_mdokon/features/cashier/domain/sale_tabs.dart';
import 'package:flutter_mdokon/features/cashier/domain/marking.dart';
import 'package:flutter_mdokon/features/cashier/domain/marking_item.dart';

/// Режим цены продажи: розница / опт / банк.
enum SalePriceMode {
  retail(0, 'sale_price'),
  wholesale(1, 'wholesale_price'),
  bank(2, 'bank_price');

  const SalePriceMode(this.id, this.labelKey);

  final int id;
  final String labelKey;

  static SalePriceMode byId(dynamic id) =>
      SalePriceMode.values.firstWhere((e) => e.id == id, orElse: () => SalePriceMode.retail);
}

/// Быстрые операции над выбранной позицией чека.
///
/// `+` количество, `-` сумма позиции, `*` цена продажи, `/` упаковка,
/// `%` скидка в процентах, `s` скидка суммой на позицию, `%-` скидка суммой на чек.
enum SaleShortcut {
  quantity('+', 'quantity'),
  lineTotal('-', 'line_amount'),
  price('*', 'sale_price'),
  unit('/', 'packaging'),
  discountPercent('%', 'discount_percent_on_cheque'),
  discountLine('s', 'discount_sum_on_item'),
  discountAmount('%-', 'discount_sum_on_cheque');

  const SaleShortcut(this.symbol, this.labelKey);

  final String symbol;

  /// Ключ перевода для пункта меню «…».
  final String labelKey;

  /// Операции, доступные из меню чека. Количество меняется степпером,
  /// упаковка — диалогом при добавлении товара.
  static const menu = [price, discountPercent, discountLine, discountAmount];

  /// Разрешена ли операция текущему пользователю. Как в desktop-кассе
  /// (`Tab.js`): смена цены закрыта ролью CASHBOX_CHANGE_SALE_PRICE, любые
  /// скидки — CASHBOX_DISCOUNT.
  bool get allowed => switch (this) {
        price => checkRole('CASHBOX_CHANGE_SALE_PRICE'),
        discountPercent || discountLine || discountAmount => checkRole('CASHBOX_DISCOUNT'),
        _ => true,
      };

  /// Пункты меню чека, оставшиеся после проверки ролей.
  static List<SaleShortcut> get allowedMenu =>
      menu.where((shortcut) => shortcut.allowed).toList();
}

/// Состояние экрана продажи: корзина, скидки, быстрые операции,
/// расходы, долги клиентов и отправка чека агентом.
///
/// Модель не знает ни про BuildContext, ни про навигацию — страница только
/// рисует состояние и реагирует на возвращённые флаги.
class SaleModel extends ChangeNotifier {
  final SaleRepository repository;
  final PostponedChequeRepository postponedRepository;
  final SupplierDebtRepository supplierRepository;
  final GetStorage storage;

  SaleModel({
    SaleRepository? repository,
    PostponedChequeRepository? postponedRepository,
    SupplierDebtRepository? supplierRepository,
    GetStorage? storage,
  })  : repository = repository ?? const SaleRepository(),
        postponedRepository = postponedRepository ?? const PostponedChequeRepository(),
        supplierRepository = supplierRepository ?? const SupplierDebtRepository(),
        storage = storage ?? GetStorage();

  // --- Чек ---------------------------------------------------------------

  Map data = emptyCheque();
  Map cashbox = {};

  /// Режим редактирования чека, пришедшего с кассы (агент).
  bool isEdit = false;

  /// Значение в поле быстрых операций.
  String shortcutValue = '';

  bool _busy = false;
  bool get busy => _busy;

  /// Пустой чек. Валюта и режим цены переносятся из предыдущего.
  static Map emptyCheque({dynamic currencyId, dynamic activePrice}) => {
        'cashboxVersion': '',
        'login': '',
        'loyaltyBonus': 0,
        'loyaltyClientAmount': 0,
        'loyaltyClientName': '',
        'cashboxId': '',
        'change': 0,
        'chequeDate': 0,
        'chequeNumber': '',
        'clientAmount': 0,
        'clientComment': '',
        'clientId': 0,
        'currencyId': currencyId ?? '',
        'currencyName': currencyId == 2 ? 'USD' : "So'm",
        'currencyRate': 0,
        'discount': 0,
        'discountAmount': 0,
        // Параметры ручной скидки на чек (F5 — процент, F6 — сумма). Суммы по
        // позициям не хранятся: их пересчитывает manualDiscountAmounts().
        'manualDiscountKey': null,
        'manualDiscountValue': 0,
        'note': '',
        'offline': false,
        'outType': false,
        'paid': 0,
        'posId': '',
        'saleCurrencyId': '',
        'shiftId': '',
        'totalPriceBeforeDiscount': 0,
        'totalPrice': 0,
        'transactionId': '',
        'itemsList': [],
        'transactionsList': [],
        'activePrice': activePrice ?? 0,
      };

  List get items => data['itemsList'] as List;
  bool get isEmpty => items.isEmpty;
  int get lineCount => items.length;

  double get totalPrice => customNumber(data['totalPrice']);
  double get subtotal => discountPercent == 0 ? totalPrice : customNumber(data['totalPriceBeforeDiscount']);
  double get discountPercent => customNumber(data['discount']);
  double get discountSum => discountPercent == 0 ? 0 : subtotal - totalPrice;

  String get currencyName => '${data['currencyName'] ?? "So'm"}';
  SalePriceMode get priceMode => SalePriceMode.byId(data['activePrice']);

  bool get isAgent => cashbox['isAgent'] == true;
  bool get saleMinus => customIf(cashbox['saleMinus']);
  /// Смена валюты разрешена настройками кассы.
  bool get currencyChangeAllowed => customIf(storage.read('changeCurrencyOnSale'));

  /// …и доступна прямо сейчас — только на пустом чеке.
  bool get canChangeCurrency => currencyChangeAllowed && isEmpty;

  /// Индекс выбранной позиции или -1.
  int get selectedIndex => items.indexWhere((e) => e['selected'] == true);
  Map? get selectedItem => selectedIndex == -1 ? null : items[selectedIndex] as Map;

  // --- Инициализация -----------------------------------------------------

  /// Подтягивает кассу, пользователя и справочник расходов.
  /// [returnCheque] — чек, возвращённый агенту на редактирование.
  Future<void> init({Map? returnCheque}) async {
    cashbox = storage.read('cashbox') ?? {};
    final user = storage.read('user') ?? {};

    data['currencyId'] = cashbox['defaultCurrency'];
    data['currencyName'] = cashbox['defaultCurrency'] == 2 ? 'USD' : "So'm";
    data['cashierLogin'] = user['login'];
    data['cashierName'] = '${user['firstName'] ?? ''}';

    if (isAgent && returnCheque != null && returnCheque.isNotEmpty) {
      data = Map.from(returnCheque);
    }

    // Вкладка №1 создана до `init()` со своим пустым чеком — привязываем её к
    // тому, который модель набирает на самом деле.
    _syncActiveTab();

    notifyListeners();
    await loadExpenses();
  }

  /// Смена валюты чека доступна только на пустом чеке.
  void toggleCurrency() {
    if (!canChangeCurrency) return;
    final toUsd = data['currencyId'] == 1;
    data['currencyId'] = toUsd ? 2 : 1;
    data['currencyName'] = toUsd ? 'USD' : "So'm";
    notifyListeners();
  }

  void setPriceMode(SalePriceMode mode) {
    data['activePrice'] = mode.id;
    notifyListeners();
  }

  void setShortcutValue(String value) {
    shortcutValue = value;
    notifyListeners();
  }

  // --- Корзина -----------------------------------------------------------

  /// Товары, выбранные в каталоге. Возвращает `true`, если для позиции нужен
  /// диалог упаковки — страница показывает [productWithParams].
  bool addScannedProducts(List products) {
    for (final raw in products) {
      final product = Map.from(raw as Map);
      product['discount'] = 0;
      product['outType'] = false;
      product['wholesale'] = priceMode == SalePriceMode.wholesale;
      product['bank'] = priceMode == SalePriceMode.bank;

      final units = product['unitList'];
      if (units is List && units.isNotEmpty) {
        openUnitDialog(product);
        return true;
      }

      // Маркировочный товар собирается в одну позицию: количество равно числу кодов.
      final code = normalizeScannedCode(product['markingNumber']);
      if (code.isNotEmpty) {
        _addMarkingProduct(product, code);
        continue;
      }

      final index = items.indexWhere((e) => e['productId'] == product['productId']);
      if (index != -1 && !saleMinus && customNumber(items[index]['quantity']) >= customNumber(items[index]['balance'])) {
        showDangerToast('limit_exceeded'.tr());
        continue;
      }
      _addToList(product);
    }
    notifyListeners();
    return false;
  }

  /// Добавление позиции в чек с пересчётом итогов.
  void _addToList(Map response, {dynamic weight = 0}) {
    data['totalPrice'] = 0;
    final index = items.indexWhere((e) => e['balanceId'] == response['balanceId']);

    if (index == -1) {
      if (!response.containsKey('quantity') && weight != 0) {
        response['quantity'] = weight;
      }
      response['selected'] = false;
      response['totalPrice'] = 0;
      response['originalSalePrice'] = response['salePrice'];
      items.add(response);

      for (final item in items) {
        item['selected'] = false;
      }
      items.last['selected'] = true;
    } else {
      if (response['quantity'] != '') {
        if (customNumber(weight) > 0) {
          items[index]['quantity'] = customNumber(items[index]['quantity']) + customNumber(weight);
        } else {
          items[index]['quantity'] = customNumber(response['quantity']);
        }
      } else {
        items[index]['quantity'] = response['quantity'];
      }
      items[index]['discount'] = 0;
    }

    _recalculateFromPriceMode();
  }

  // --- Маркировка --------------------------------------------------------

  /// Строка чека с этим товаром, собирающая коды маркировки, или -1.
  int markingLineIndex(dynamic productId) =>
      items.indexWhere((e) => e['productId'] == productId && isMarkingItem(e as Map));

  /// Отсканирован маркировочный товар: код уходит в существующую строку этого
  /// товара, а не создаёт вторую.
  void _addMarkingProduct(Map product, String code) {
    final index = markingLineIndex(product['productId']);
    if (index != -1) {
      _applyMarkingCode(index, code);
      return;
    }
    setMarkingCodes(product, [code]);
    _addToList(product);
  }

  /// Добавить код к готовой строке чека (кнопка «+» на маркировочной позиции).
  MarkingAddResult addMarkingCodeToLine(int index, String code) {
    if (index < 0 || index >= items.length) return MarkingAddResult.duplicate;
    final result = _applyMarkingCode(index, code);
    notifyListeners();
    return result;
  }

  MarkingAddResult _applyMarkingCode(int index, String code) {
    final item = items[index] as Map;
    final result = addMarkingCode(
      item,
      code,
      balance: saleMinus ? null : customNumber(item['balance']),
    );
    switch (result) {
      case MarkingAddResult.duplicate:
        showDangerToast('marking_already_scanned'.tr());
      case MarkingAddResult.limitExceeded:
        showDangerToast('limit_exceeded'.tr());
      case MarkingAddResult.added:
        item['discount'] = 0;
        _recalculate(notify: false);
    }
    return result;
  }

  /// Убрать код со строки чека («−» на маркировочной позиции).
  /// Последний код удаляет саму позицию — товара без кода в чеке быть не может.
  void removeMarkingCodeFromLine(int index, String code) {
    if (index < 0 || index >= items.length) return;
    final item = items[index] as Map;
    if (!removeMarkingCode(item, code)) return;
    if (markingCodes(item).isEmpty) {
      deleteLine(index);
      return;
    }
    _recalculate();
  }

  /// Пересчёт цен по режиму (розница / опт / банк) и суммы чека.
  void _recalculateFromPriceMode() {
    for (final item in items) {
      if (item['wholesale'] == true) {
        item['salePrice'] = customNumber(item['wholesalePrice']);
      } else if (item['bank'] == true) {
        item['salePrice'] = customNumber(item['bankPrice']);
      }
    }
    _recalculate(notify: false);
  }

  void selectLine(int index) {
    for (var i = 0; i < items.length; i++) {
      items[i]['selected'] = i == index;
    }
    notifyListeners();
  }

  /// Ручное изменение количества степпером.
  void setQuantity(int index, num quantity) {
    if (index < 0 || index >= items.length) return;
    // Количество маркировочной позиции задаётся кодами, а не степпером:
    // «+» сканирует новый код, «−» открывает список и удаляет выбранный.
    if (isMarkingItem(items[index] as Map)) {
      showDangerToast('marking_quantity_by_codes'.tr());
      return;
    }
    if (quantity <= 0) {
      deleteLine(index);
      return;
    }
    if (!saleMinus && quantity > customNumber(items[index]['balance'])) {
      showDangerToast('limit_exceeded'.tr());
      return;
    }
    items[index]['quantity'] = quantity;
    items[index]['discount'] = 0;
    _recalculate();
  }

  void deleteLine(int index) {
    // Удаление позиции — первое, что спрашивают при разборе «чек не сошёлся»,
    // поэтому уровень audit, а не debug.
    final line = index >= 0 && index < items.length ? items[index] : null;
    if (line != null) {
      appLog.audit('sale.line_deleted', {
        'name': '${line['name'] ?? ''}',
        'quantity': line['quantity'],
        'price': line['price'],
      });
    }
    if (items.length == 1) {
      clearCheque();
      return;
    }
    items.removeAt(index);
    _recalculate();
  }

  /// Полный сброс чека с сохранением валюты и режима цены.
  void clearCheque() {
    if (items.isNotEmpty) {
      appLog.audit('sale.cheque_cleared', {'lines': items.length});
    }
    final user = storage.read('user') ?? {};
    data = emptyCheque(
      currencyId: data['currencyId'],
      activePrice: data['activePrice'],
    )
      ..['cashierLogin'] = user['login']
      ..['cashierName'] = '${user['firstName'] ?? ''}';
    shortcutValue = '';
    _syncActiveTab();
    notifyListeners();
  }

  // --- Вкладки чеков -----------------------------------------------------

  /// Параллельно набираемые чеки. Только планшет: на телефоне панель вкладок
  /// не рисуется, и состояние так и остаётся из одной вкладки.
  SaleTabsState _tabs = initialSaleTabs(emptyCheque());
  SaleTabsState get tabs => _tabs;

  int get activeTabId => _tabs.activeId;
  bool get canAddTab => _tabs.canAdd;
  bool get canCloseTab => _tabs.canClose;

  /// Новая вкладка с пустым чеком. Валюта и режим цены переносятся из
  /// текущего чека — кассир выбрал их для этой смены, а не для этого чека.
  void addTab() {
    if (!_tabs.canAdd) return;
    final user = storage.read('user') ?? {};
    final blank = emptyCheque(
      currencyId: data['currencyId'],
      activePrice: data['activePrice'],
    )
      ..['cashierLogin'] = user['login']
      ..['cashierName'] = '${user['firstName'] ?? ''}';

    _tabs = addSaleTab(_tabs, data, blank);
    _openActiveTab();
  }

  void switchTab(int id) {
    final next = switchSaleTab(_tabs, id, data);
    if (identical(next, _tabs)) return;
    _tabs = next;
    _openActiveTab();
  }

  /// Закрыть вкладку. Набранный в ней чек пропадает — подтверждение
  /// спрашивает UI, модель молча выполняет.
  void closeTab(int id) {
    final wasActive = id == _tabs.activeId;
    final next = closeSaleTab(_tabs, id, data);
    if (identical(next, _tabs)) return;
    _tabs = next;
    if (wasActive) {
      _openActiveTab();
    } else {
      notifyListeners();
    }
  }

  /// Чек активной вкладки становится текущим.
  void _openActiveTab() {
    data = _tabs.active.cheque;
    shortcutValue = '';
    _recalculate();
  }

  /// Снимок текущего чека во вкладке. Зовётся там, где `data` подменяется
  /// целиком (сброс чека, открытие отложенного): иначе вкладка держала бы
  /// ссылку на карту, которой в модели больше нет.
  void _syncActiveTab() {
    _tabs = SaleTabsState(
      tabs: [
        for (final tab in _tabs.tabs) tab.id == _tabs.activeId ? tab.copyWith(cheque: data) : tab,
      ],
      activeId: _tabs.activeId,
    );
  }

  /// Ручная скидка на чек, заданная кассиром (F5 — процент, F6 — сумма).
  ManualDiscount? get manualDiscount {
    final key = switch (data['manualDiscountKey']) {
      'f5' => ManualDiscountKey.f5,
      'f6' => ManualDiscountKey.f6,
      _ => null,
    };
    if (key == null) return null;
    final value = customNumber(data['manualDiscountValue']);
    if (value <= 0) return null;
    return ManualDiscount(key, value);
  }

  /// Пересчёт итогов чека.
  ///
  /// Скидка хранится параметрами, а суммы по позициям выводятся здесь заново —
  /// поэтому после смены количества, цены или состава корзины процент скидки
  /// остаётся тем, который ввёл кассир.
  ///
  /// Инварианты, на которые опирается остальной код:
  /// позиция и чек хранят НЕТТО в `totalPrice`, БРУТТО — в
  /// `totalPriceBeforeDiscount`, сумму скидки — в `discountAmount`.
  /// В серверный формат (`totalPrice` = БРУТТО) чек переводит
  /// `cashbox_model.dart` перед отправкой на `cheque-v2`.
  void _recalculate({bool notify = true}) {
    final base = items
        .map<num>((item) => customNumber(item['quantity']) * customNumber(item['salePrice']))
        .toList();
    final fixed = items
        .map<num?>((item) => item['fixedDiscount'] == null ? null : customNumber(item['fixedDiscount']))
        .toList();

    final amounts = manualDiscountAmounts(base, fixed, manualDiscount);

    num gross = 0;
    num discount = 0;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      item['totalPriceOriginal'] = base[i];
      item['totalPriceBeforeDiscount'] = base[i];
      item['discountAmount'] = amounts[i];
      item['totalPrice'] = base[i] - amounts[i];
      item['discount'] = base[i] == 0 ? 0 : amounts[i] * 100 / base[i];
      gross += base[i];
      discount += amounts[i];
    }

    data['totalPriceBeforeDiscount'] = gross;
    data['discountAmount'] = discount;
    data['totalPrice'] = gross - discount;
    data['discount'] = gross == 0 ? 0 : discount * 100 / gross;

    if (notify) notifyListeners();
  }

  // --- Быстрые операции --------------------------------------------------

  /// Применяет быструю операцию к введённому значению.
  /// Возвращает `true`, если нужно открыть диалог упаковки (операция `/`).
  bool applyShortcut(SaleShortcut shortcut) {
    final input = shortcutValue.trim();
    if (input.isEmpty && shortcut != SaleShortcut.unit) return false;

    final isFloat = input.contains('.');
    final item = selectedItem;
    final index = selectedIndex;

    switch (shortcut) {
      case SaleShortcut.quantity:
        if (item == null) return _warn('choose_product');
        if (isFloat && item['uomId'] == 1) return _warn('wrong_quantity');
        final value = customNumber(input);
        if (!saleMinus && value > customNumber(item['balance'])) {
          showDangerToast('limit_exceeded'.tr());
          items[index]['quantity'] = item['balance'];
        } else {
          items[index]['quantity'] = value;
        }
        _clearShortcut();
        _recalculateTotalsOnly();

      case SaleShortcut.price:
        if (item == null) return _warn('choose_product');
        final value = customNumber(input);
        if (value < customNumber(item['price'])) {
          return _warn('sale_price_cannot_be_lower_than_receipt_price');
        }
        items[index]['salePrice'] = value;
        _clearShortcut();
        _recalculateTotalsOnly();

      case SaleShortcut.lineTotal:
        if (item == null) return _warn('choose_product');
        if (item['uomId'] == 1) return _warn('wrong_quantity');
        final quantity = customNumber(input) / customNumber(item['salePrice']);
        if (!saleMinus && quantity > customNumber(item['balance'])) {
          return _warn('limit_exceeded');
        }
        items[index]['quantity'] = quantity;
        _clearShortcut();
        _recalculateTotalsOnly();

      case SaleShortcut.unit:
        _clearShortcut();
        final units = item?['unitList'];
        if (item == null || units is! List || units.isEmpty) return false;
        openUnitDialog(item);
        return true;

      case SaleShortcut.discountPercent:
        _applyDiscount('%', customNumber(input));
        _clearShortcut();

      case SaleShortcut.discountLine:
        _applyDiscount('s', customNumber(input));
        _clearShortcut();

      case SaleShortcut.discountAmount:
        _applyDiscount('%-', customNumber(input));
        _clearShortcut();
    }

    notifyListeners();
    return false;
  }

  bool _warn(String message) {
    showDangerToast(message.tr());
    _clearShortcut();
    notifyListeners();
    return false;
  }

  void _clearShortcut() => shortcutValue = '';

  void _recalculateTotalsOnly() => _recalculate(notify: false);

  /// Скидки: `%` — процент на чек (F5), `%-` — сумма на чек (F6),
  /// `s` — сумма на выбранную позицию (F7).
  ///
  /// Сохраняются только параметры — суммы раскидывает `_recalculate()`.
  void _applyDiscount(String key, double value) {
    if (key == 's') {
      final item = selectedItem;
      if (item == null) return;
      final base = customNumber(item['quantity']) * customNumber(item['salePrice']);
      if (value > base) {
        showDangerToast('discount_exceeds_line'.tr());
        return;
      }
      item['fixedDiscount'] = value <= 0 ? null : value;
      _recalculate(notify: false);
      return;
    }

    if (key == '%' && value > 100) {
      showDangerToast('discount_exceeds_total'.tr());
      return;
    }
    if (key == '%-' && value > customNumber(data['totalPriceBeforeDiscount'])) {
      showDangerToast('discount_exceeds_total'.tr());
      return;
    }

    // Новая скидка на чек отменяет ранее заданные суммы по позициям (F7).
    for (final item in items) {
      item['fixedDiscount'] = null;
    }
    data['manualDiscountKey'] = value <= 0 ? null : (key == '%' ? 'f5' : 'f6');
    data['manualDiscountValue'] = value;
    _recalculate(notify: false);
  }

  // --- Товар с упаковкой -------------------------------------------------

  Map productWithParams = {
    'selectedUnit': {'name': '', 'quantity': ''},
    'modificationList': [],
    'unitList': [],
  };

  String packagingInput = '';
  String pieceInput = '';
  double unitQuantity = 0;
  double unitTotalPrice = 0;

  void openUnitDialog(Map product) {
    productWithParams = product;
    productWithParams['quantity'] = '';
    productWithParams['totalPrice'] = '';
    productWithParams['selectedUnit'] = (product['unitList'] as List).first;
    packagingInput = '';
    pieceInput = '';
    unitQuantity = 0;
    unitTotalPrice = 0;
    notifyListeners();
  }

  void setPackaging(String value) {
    packagingInput = value;
    _calculateUnit();
  }

  void setPiece(String value) {
    pieceInput = value;
    _calculateUnit();
  }

  bool get canAddUnit => unitQuantity > 0;

  /// Пересчёт «упаковок + штук» в количество и сумму позиции.
  void _calculateUnit() {
    final packaging = customNumber(packagingInput);
    final piece = customNumber(pieceInput);
    final salePrice = customNumber(productWithParams['salePrice']);
    final inPack = customNumber(productWithParams['selectedUnit']['quantity']);

    if (packaging == 0 && piece == 0) {
      unitQuantity = 0;
      unitTotalPrice = 0;
      notifyListeners();
      return;
    }

    if (piece > inPack && inPack > 0) {
      pieceInput = '';
      notifyListeners();
      return;
    }

    if (piece == 0) {
      unitQuantity = packaging;
    } else if (inPack > 0 && piece == inPack) {
      unitQuantity = packaging + 1;
    } else if (inPack > 0) {
      unitQuantity = packaging + piece / inPack;
    } else {
      unitQuantity = packaging;
    }

    unitTotalPrice = salePrice * unitQuantity;
    notifyListeners();
  }

  /// Подтверждение диалога упаковки.
  void confirmUnit() {
    if (!canAddUnit) return;
    productWithParams['quantity'] = unitQuantity;
    _addToList(productWithParams);
    packagingInput = '';
    pieceInput = '';
    unitQuantity = 0;
    unitTotalPrice = 0;
    notifyListeners();
  }

  // --- Отправка чека агентом --------------------------------------------

  Future<bool> sendToCashbox() async {
    if (_busy || isEmpty) return false;
    _setBusy(true);
    try {
      final cheque = Map.from(data);
      cheque['currencyId'] ??= cashbox['defaultCurrency'];
      if (cheque['currencyId'] == '') cheque['currencyId'] = cashbox['defaultCurrency'];

      final ok = await repository.sendToCashbox(
        posId: cashbox['posId'],
        cheque: cheque,
        id: isEdit ? data['id'] : null,
      );
      if (ok) clearCheque();
      return ok;
    } finally {
      _setBusy(false);
    }
  }

  // --- Расходы -----------------------------------------------------------

  List expenses = [];
  Map expenseOut = {'expenseId': '', 'note': '', 'amountOut': ''};

  Future<void> loadExpenses() async {
    final response = await repository.expenses();
    if (response.isEmpty) return;
    expenses = response;
    expenseOut['expenseId'] = '${response.first['id']}';
    notifyListeners();
  }

  void setExpenseField(String key, dynamic value) {
    expenseOut[key] = value;
    notifyListeners();
  }

  bool get canSubmitExpense => '${expenseOut['amountOut']}'.isNotEmpty && !_busy;

  Future<bool> submitExpense() async {
    if (!canSubmitExpense) return false;
    _setBusy(true);
    try {
      final payload = {
        ...expenseOut,
        'cashboxId': '${cashbox['cashboxId']}',
        'posId': '${cashbox['posId']}',
        'currencyId': '${cashbox['defaultCurrency']}',
        'shiftId': _shiftId,
      };
      final ok = await repository.createExpense(payload);
      if (ok) expenseOut = {'expenseId': expenseOut['expenseId'], 'note': '', 'amountOut': ''};
      return ok;
    } finally {
      _setBusy(false);
    }
  }

  dynamic get _shiftId {
    final shift = storage.read('shift');
    return shift != null ? shift['id'] : cashbox['id'];
  }

  // --- Долги клиентов ----------------------------------------------------

  List allClients = [];
  List clients = [];
  Map debtIn = {'cash': '', 'terminal': '', 'clientId': 0};

  Future<void> loadDebtClients() async {
    final response = await repository.debtClients(cashbox['posId']);
    for (final client in response) {
      client['selected'] = false;
    }
    allClients = List.from(response);
    clients = List.from(response);
    resetDebtForm();
  }

  void searchDebtClients(String query) {
    final value = query.trim().toLowerCase();
    clients = value.isEmpty
        ? List.from(allClients)
        : allClients.where((client) {
            final name = '${client['clientName'] ?? ''}'.toLowerCase();
            final phone = '${client['phone1'] ?? ''}'.toLowerCase();
            return name.contains(value) || phone.contains(value);
          }).toList();
    notifyListeners();
  }

  void selectDebtClient(int index) {
    for (var i = 0; i < clients.length; i++) {
      clients[i]['selected'] = i == index;
    }
    debtIn['clientId'] = clients[index]['clientId'];
    debtIn['currencyId'] = clients[index]['currencyId'];
    debtIn['currencyName'] = clients[index]['currencyName'];
    notifyListeners();
  }

  void setDebtField(String key, String value) {
    debtIn[key] = value;
    notifyListeners();
  }

  void resetDebtForm() {
    debtIn = {'cash': '', 'terminal': '', 'clientId': 0};
    notifyListeners();
  }

  bool get canSubmitDebt =>
      debtIn['clientId'] != 0 &&
      ('${debtIn['cash']}'.isNotEmpty || '${debtIn['terminal']}'.isNotEmpty) &&
      !_busy;

  Future<bool> submitDebt() async {
    if (!canSubmitDebt) return false;
    _setBusy(true);
    try {
      final transactions = [];
      double amountIn = 0;

      for (final entry in [
        ('cash', 1),
        ('terminal', 2),
      ]) {
        final amount = customNumber(debtIn[entry.$1]);
        if (amount <= 0) continue;
        transactions.add({
          'amountIn': amount,
          'amountOut': '',
          'paymentTypeId': entry.$2,
          'paymentPurposeId': 5,
        });
        amountIn += amount;
      }

      final ok = await repository.repayDebt({
        ...debtIn,
        'amountIn': amountIn,
        'amountOut': 0,
        'cashboxId': cashbox['cashboxId'],
        'posId': cashbox['posId'],
        'shiftId': _shiftId,
        'transactionsList': transactions,
      });
      if (ok) resetDebtForm();
      return ok;
    } finally {
      _setBusy(false);
    }
  }

  // --- Клиенты агента ----------------------------------------------------

  Timer? _searchDebounce;

  Future<void> loadClients({String search = ''}) async {
    final response = await repository.clients(search: search);
    for (final client in response) {
      client['selected'] = false;
    }
    clients = List.from(response);
    notifyListeners();
  }

  void searchClients(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () => loadClients(search: query));
  }

  void selectClient(int index) {
    for (var i = 0; i < clients.length; i++) {
      clients[i]['selected'] = i == index;
    }
    notifyListeners();
  }

  /// Привязать выбранного клиента к чеку.
  void attachSelectedClient() {
    final client = clients.firstWhere((e) => e['selected'] == true, orElse: () => null);
    if (client == null) return;
    data['clientName'] = '${client['name']}';
    data['clientId'] = '${client['id']}';
    data['clientComment'] = '${client['comment'] ?? ''}';
    data['clientAddress'] = '${client['address'] ?? ''}';
    data['clientPhone1'] = '${client['phone1'] ?? ''}';
    data['clientPhone2'] = '${client['phone2'] ?? ''}';
    notifyListeners();
  }

  Future<bool> createClient(Map payload) async {
    if (_busy) return false;
    _setBusy(true);
    try {
      final ok = await repository.createClient(payload);
      if (ok) await loadClients();
      return ok;
    } finally {
      _setBusy(false);
    }
  }

  // --- Отложенные чеки ---------------------------------------------------

  /// Открытый сейчас список отложенных.
  List<PostponedCheque> postponed = [];

  /// Выбранная строка списка или -1.
  int postponedIndex = -1;

  PostponedCheque? get selectedPostponed =>
      postponedIndex < 0 || postponedIndex >= postponed.length ? null : postponed[postponedIndex];

  /// Офлайновый список из хранилища устройства.
  List get _storedPostponed {
    final raw = storage.read(postponedStorageKey);
    return raw is List ? List.from(raw) : [];
  }

  /// Отложить текущий чек.
  ///
  /// Куда — решает настройка: `postponeOnline` кладёт чек на сервер точки,
  /// `postponeOffline` — в хранилище устройства. Настройки взаимоисключающие,
  /// поэтому режим приходит сюда уже выбранным.
  Future<bool> postponeCheque(PostponeStore store) async {
    if (_busy) return false;
    if (!canPostpone(data)) {
      showDangerToast('cheque_is_empty'.tr());
      return false;
    }

    _setBusy(true);
    try {
      final snapshot = postponedSnapshot(data, createdDate: DateTime.now().millisecondsSinceEpoch);

      if (store == PostponeStore.offline) {
        storage.write(postponedStorageKey, [..._storedPostponed, snapshot]);
      } else {
        final ok = await postponedRepository.save(posId: cashbox['posId'], cheque: snapshot);
        if (!ok) return false;
      }
      clearCheque();
      return true;
    } finally {
      _setBusy(false);
    }
  }

  /// Загрузить список отложенных чеков выбранного источника.
  Future<void> loadPostponed(PostponeStore store) async {
    postponedIndex = -1;
    postponed = switch (store) {
      PostponeStore.offline => parseStoredList(_storedPostponed),
      PostponeStore.online => await postponedRepository.list(cashbox['posId']),
      PostponeStore.cloud => await postponedRepository.cloud(cashbox['posId']),
    };
    notifyListeners();
  }

  void selectPostponed(int index) {
    postponedIndex = postponedIndex == index ? -1 : index;
    notifyListeners();
  }

  /// Открыть выбранный чек в корзине.
  ///
  /// Онлайновый и облачный чеки на сервере остаются: их удалит продажа по
  /// `chequeOnlineId`. Офлайновый уходит из хранилища сразу — второго места,
  /// где он мог бы закрыться, нет.
  bool openPostponed() {
    final selected = selectedPostponed;
    if (selected == null) {
      showDangerToast('choose_cheque'.tr());
      return false;
    }
    if (!currencyMatches(selected.cheque, cashbox['defaultCurrency'])) {
      showDangerToast('different_currencies'.tr());
      return false;
    }

    data = restorePostponed(
      selected.cheque,
      cashbox: cashbox,
      user: storage.read('user') ?? {},
      shiftId: _shiftId,
      source: selected.id == null ? null : selected,
    );
    shortcutValue = '';
    _syncActiveTab();

    if (selected.id == null) _removeStoredPostponed(postponedIndex);
    postponed = List.of(postponed)..removeAt(postponedIndex);
    postponedIndex = -1;

    _recalculate();
    return true;
  }

  /// Удалить выбранный чек, не открывая.
  Future<bool> deletePostponed() async {
    final selected = selectedPostponed;
    if (selected == null) {
      showDangerToast('choose_cheque'.tr());
      return false;
    }

    if (selected.id != null) {
      final ok = await postponedRepository.remove(selected.id);
      if (!ok) return false;
    } else {
      _removeStoredPostponed(postponedIndex);
    }

    postponed = List.of(postponed)..removeAt(postponedIndex);
    postponedIndex = -1;
    notifyListeners();
    return true;
  }

  void _removeStoredPostponed(int index) {
    final stored = _storedPostponed;
    if (index < 0 || index >= stored.length) return;
    storage.write(postponedStorageKey, stored..removeAt(index));
  }

  // --- Взаиморасчёт с поставщиками ---------------------------------------

  List allSuppliers = [];
  List suppliers = [];
  int supplierIndex = -1;
  Map supplierPayment = {'amount': '', 'note': ''};

  Map? get selectedSupplier =>
      supplierIndex < 0 || supplierIndex >= suppliers.length ? null : suppliers[supplierIndex] as Map;

  /// Сброс формы выдачи — при открытии и закрытии листа.
  void resetSupplierForm() {
    supplierIndex = -1;
    supplierPayment = {'amount': '', 'note': ''};
    notifyListeners();
  }

  Future<void> loadSuppliers() async {
    // После выдачи список перечитывается — выделение переносим на того же
    // поставщика, чтобы кассир увидел его новый остаток, а не потерял строку.
    final keep = selectedSupplier?['organizationId'];
    final response = await supplierRepository.list(cashbox['posId']);
    allSuppliers = List.from(response);
    suppliers = List.from(response);
    supplierIndex = keep == null
        ? -1
        : suppliers.indexWhere((e) => '${e['organizationId']}' == '$keep');
    notifyListeners();
  }

  void searchSuppliers(String query) {
    final value = query.trim().toLowerCase();
    final selected = selectedSupplier;
    suppliers = value.isEmpty
        ? List.from(allSuppliers)
        : allSuppliers.where((supplier) {
            final name = '${supplier['organizationName'] ?? ''}'.toLowerCase();
            final phone = '${supplier['phone'] ?? ''}'.toLowerCase();
            return name.contains(value) || phone.contains(value);
          }).toList();
    // Выделение держим на самом поставщике, а не на позиции в списке: после
    // фильтра индексы разъезжаются, и кассир выдал бы деньги не тому.
    supplierIndex = selected == null ? -1 : suppliers.indexOf(selected);
    notifyListeners();
  }

  void selectSupplier(int index) {
    supplierIndex = supplierIndex == index ? -1 : index;
    notifyListeners();
  }

  void setSupplierField(String key, String value) {
    supplierPayment[key] = value;
    notifyListeners();
  }

  bool get canPaySupplier =>
      selectedSupplier != null && customNumber(supplierPayment['amount']) > 0 && !_busy;

  /// Выдача денег поставщику. Долг гасится и деньги списываются из ящика одной
  /// операцией — обычным расходом провести это нельзя, долг остался бы висеть.
  Future<bool> paySupplier() async {
    if (!canPaySupplier) return false;
    final supplier = selectedSupplier!;

    _setBusy(true);
    try {
      final result = await supplierRepository.pay({
        'posId': cashbox['posId'],
        'cashboxId': cashbox['cashboxId'],
        'shiftId': _shiftId,
        'organizationId': supplier['organizationId'],
        'currencyId': supplier['currencyId'],
        'note': '${supplierPayment['note'] ?? ''}',
        'amountOut': customNumber(supplierPayment['amount']),
      });
      if (!result.ok) {
        if (result.message.isNotEmpty) showDangerToast(result.message);
        return false;
      }
      supplierPayment = {'amount': '', 'note': ''};
      // Строка остаётся выделенной — кассир видит новый остаток.
      await loadSuppliers();
      return true;
    } finally {
      _setBusy(false);
    }
  }

  // --- Служебное ---------------------------------------------------------

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
