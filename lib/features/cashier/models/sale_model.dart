import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/data/sale_repository.dart';

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
}

/// Состояние экрана продажи: корзина, скидки, быстрые операции,
/// расходы, долги клиентов и отправка чека агентом.
///
/// Модель не знает ни про BuildContext, ни про навигацию — страница только
/// рисует состояние и реагирует на возвращённые флаги.
class SaleModel extends ChangeNotifier {
  final SaleRepository repository;
  final GetStorage storage;

  SaleModel({
    SaleRepository? repository,
    GetStorage? storage,
  })  : repository = repository ?? const SaleRepository(),
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

  /// Пересчёт цен по режиму (розница / опт / банк) и суммы чека.
  void _recalculateFromPriceMode() {
    double total = 0;
    for (final item in items) {
      final quantity = customNumber(item['quantity']);
      if (item['wholesale'] == true) {
        item['salePrice'] = customNumber(item['wholesalePrice']);
      } else if (item['bank'] == true) {
        item['salePrice'] = customNumber(item['bankPrice']);
      }
      item['totalPrice'] = customNumber(item['salePrice']) * quantity;
      total += item['totalPrice'] as double;
    }
    data['totalPrice'] = total;
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
    if (items.length == 1) {
      clearCheque();
      return;
    }
    items.removeAt(index);
    _recalculate();
  }

  /// Полный сброс чека с сохранением валюты и режима цены.
  void clearCheque() {
    final user = storage.read('user') ?? {};
    data = emptyCheque(
      currencyId: data['currencyId'],
      activePrice: data['activePrice'],
    )
      ..['cashierLogin'] = user['login']
      ..['cashierName'] = '${user['firstName'] ?? ''}';
    shortcutValue = '';
    notifyListeners();
  }

  /// Пересчёт итогов с учётом уже применённых скидок по позициям.
  void _recalculate() {
    double total = 0;
    double beforeDiscount = 0;

    for (final item in items) {
      item['totalPrice'] = customNumber(item['quantity']) * customNumber(item['salePrice']);
      beforeDiscount += item['totalPriceOriginal'] != null
          ? customNumber(item['totalPriceOriginal'])
          : customNumber(item['totalPrice']);
      total += customNumber(item['totalPrice']);
    }

    data['discount'] = beforeDiscount == 0 ? 0 : 100 - (total * 100 / beforeDiscount);
    data['totalPriceBeforeDiscount'] = beforeDiscount;
    data['totalPrice'] = total;
    notifyListeners();
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

  void _recalculateTotalsOnly() {
    double total = 0;
    for (final item in items) {
      item['totalPrice'] = customNumber(item['quantity']) * customNumber(item['salePrice']);
      total += customNumber(item['totalPrice']);
    }
    data['totalPrice'] = total;
  }

  /// Скидки: `%` — процент на чек, `s` — сумма на позицию, `%-` — сумма на чек.
  void _applyDiscount(String key, double value) {
    if (key != 's' && discountPercent > 0) {
      data['discount'] = 0;
      data['totalPrice'] = customNumber(data['totalPriceBeforeDiscount']);
      data['totalPriceBeforeDiscount'] = 0;
      for (final item in items) {
        item['discount'] = 0;
        item['totalPrice'] = customNumber(item['salePrice']) * customNumber(item['quantity']);
      }
    }

    if (key == '%') {
      if (value > 100) {
        showDangerToast('Скидка не может быть больше 100%');
        return;
      }
      data['discount'] = value;
      data['totalPrice'] = 0;
      for (final item in items) {
        data['totalPrice'] = customNumber(data['totalPrice']) + customNumber(item['salePrice']) * customNumber(item['quantity']);
        item['discount'] = value;
        item['discountAmount'] = customNumber(item['totalPrice']) * (value / 100);
        item['totalPrice'] = customNumber(item['totalPrice']) - customNumber(item['totalPrice']) * (value / 100);
      }
      data['totalPriceBeforeDiscount'] = data['totalPrice'];
      data['discountAmount'] = customNumber(data['totalPriceBeforeDiscount']) * (value / 100);
      data['totalPrice'] = customNumber(data['totalPrice']) - customNumber(data['totalPrice']) * (customNumber(data['discount']) / 100);
      return;
    }

    if (key == 's') {
      data['totalPrice'] = 0;
      data['totalPriceBeforeDiscount'] = 0;
      for (final item in items) {
        if (item['selected'] == true) {
          if (customNumber(item['discount']) == 0) {
            item['totalPriceOriginal'] = item['totalPrice'];
            item['totalPrice'] = customNumber(item['totalPrice']) - value;
          } else {
            item['totalPrice'] = customNumber(item['totalPriceOriginal']) - value;
          }
          final original = customNumber(item['totalPriceOriginal']);
          item['discount'] = original == 0 ? 0 : 100 / (original / value);
        }

        data['totalPriceBeforeDiscount'] = customNumber(data['totalPriceBeforeDiscount']) +
            (item['totalPriceOriginal'] != null
                ? customNumber(item['totalPriceOriginal'])
                : customNumber(item['totalPrice']));
        data['totalPrice'] = customNumber(data['totalPrice']) + customNumber(item['totalPrice']);
        item['discountAmount'] = customNumber(item['totalPriceOriginal']) - customNumber(item['totalPrice']);
      }

      final before = customNumber(data['totalPriceBeforeDiscount']);
      data['discount'] = before == 0 ? 0 : 100 - (customNumber(data['totalPrice']) * 100 / before);
      data['discountAmount'] = before - customNumber(data['totalPrice']);
      return;
    }

    if (key == '%-') {
      final total = customNumber(data['totalPrice']);
      if (total == 0) return;
      final percent = 100 / (total / value);
      data['discountAmount'] = value;
      data['discount'] = percent;
      data['totalPriceBeforeDiscount'] = total;
      data['totalPrice'] = total - (total * percent) / 100;

      for (final item in items) {
        item['discountAmount'] = value;
        item['discount'] = percent;
        item['totalPriceBeforeDiscount'] = data['totalPrice'];
        item['totalPrice'] = customNumber(item['totalPrice']) - (customNumber(item['totalPrice']) * percent) / 100;
      }
    }
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
