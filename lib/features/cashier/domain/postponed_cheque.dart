// Отложенные чеки — порт `addChequeToSaved` / `getChequeFromSaved` /
// `selectSavedChequeDone` / `selectCloudChequeDone` из `src/components/cashbox/Tab.js`.
//
// Три источника, один формат:
//
// * **офлайн** — чек лежит в `GetStorage` под ключом [postponedStorageKey]
//   (десктоп держит его в `localStorage.chequeList`). Виден только на этом
//   устройстве, сервер о нём не знает;
// * **онлайн** — чек уходит на `cheque-online-cashbox` и открывается на любой
//   кассе точки;
// * **облако** — чек, присланный агентом (`cheque-online-list`). Отличается от
//   онлайн-отложенного только тем, что реквизиты клиента и агента лежат не
//   внутри чека, а рядом с ним, в строке списка.
//
// Здесь только чистые функции: разбор ответа, снимок чека для хранения и
// восстановление чека под текущую кассу. Сеть — в `postponed_cheque_repository.dart`,
// состояние — в `SaleModel`.
library;

import 'dart:convert';

import 'package:intl/intl.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';

/// Где лежит отложенный чек.
enum PostponeStore {
  /// `GetStorage` этого устройства.
  offline,

  /// Сервер точки (`cheque-online-cashbox`).
  online,

  /// Чек агента из облака (`cheque-online-list`). Только чтение: касса его
  /// открывает или удаляет, но не создаёт.
  cloud,
}

/// Ключ `GetStorage`, под которым лежит офлайновый список.
const String postponedStorageKey = 'chequeList';

/// Поля, которые касса проставляет заново при пробитии чека. Отложенный чек мог
/// пролежать смену и день, поэтому старые значения не переносим: номер, время и
/// транзакцию сгенерирует `CashboxModel.initializeDataFields()`, а способы
/// оплаты соберёт экран оплаты из справочника.
const List<String> _volatileKeys = [
  'chequeDate',
  'chequeNumber',
  'transactionId',
  'paymentTypes',
  'paid',
  'change',
  'cashboxVersion',
  'device',
  'selected',
  'createdDate',
];

/// Отложенный чек одной строкой списка.
class PostponedCheque {
  const PostponedCheque({
    required this.cheque,
    this.id,
    this.createdDate,
    this.clientId,
    this.clientName = '',
    this.organizationId,
    this.organizationName = '',
    this.agentLogin = '',
    this.agentName = '',
  });

  /// Сам чек в формате кассы.
  final Map cheque;

  /// Идентификатор строки на сервере. `null` у офлайновых.
  final dynamic id;

  /// Когда отложили — миллисекунды.
  final dynamic createdDate;

  final dynamic clientId;
  final String clientName;
  final dynamic organizationId;
  final String organizationName;
  final String agentLogin;
  final String agentName;

  /// Сумма чека. Считаем по позициям, а не по `totalPrice`: у агентских чеков
  /// из облака итог на верхнем уровне не заполнен.
  num get total => postponedTotal(cheque);

  int get lineCount => cheque['itemsList'] is List ? (cheque['itemsList'] as List).length : 0;

  /// Чей это чек — клиент, организация или агент. Пусто, если никого не выбрали.
  String get subtitle {
    for (final name in [clientName, organizationName, agentName]) {
      if (name.trim().isNotEmpty) return name.trim();
    }
    for (final key in ['clientName', 'organizationName', 'agentName']) {
      final name = '${cheque[key] ?? ''}'.trim();
      if (name.isNotEmpty) return name;
    }
    return '';
  }
}

/// Сумма позиций чека.
num postponedTotal(Map cheque) {
  final items = cheque['itemsList'];
  if (items is! List) return 0;
  num sum = 0;
  for (final item in items) {
    if (item is Map) sum += customNumber(item['totalPrice']);
  }
  return sum;
}

/// Есть ли что откладывать. Пустой чек — не чек.
bool canPostpone(Map cheque) {
  final items = cheque['itemsList'];
  return items is List && items.isNotEmpty;
}

/// Снимок чека для хранения.
///
/// `selected` снимается со строк: выделение — состояние экрана, а не чека, и
/// после открытия оно всё равно назначается заново.
Map<String, dynamic> postponedSnapshot(Map cheque, {required dynamic createdDate}) {
  final copy = Map<String, dynamic>.from(cheque);
  copy['selected'] = false;
  copy['createdDate'] = createdDate;

  final items = cheque['itemsList'];
  if (items is List) {
    copy['itemsList'] = items
        .map((item) => item is Map ? (Map<String, dynamic>.from(item)..['selected'] = false) : item)
        .toList();
  }
  return copy;
}

/// Строка ответа сервера → [PostponedCheque].
///
/// Чек приходит строкой JSON внутри поля `cheque`. Битую строку пропускаем:
/// один испорченный чек не должен схлопывать весь список.
PostponedCheque? parsePostponedRow(dynamic raw) {
  if (raw is! Map) return null;

  final chequeField = raw['cheque'];
  Map? cheque;
  if (chequeField is Map) {
    cheque = chequeField;
  } else if (chequeField is String && chequeField.isNotEmpty) {
    try {
      final decoded = jsonDecode(chequeField);
      if (decoded is Map) cheque = decoded;
    } catch (_) {
      return null;
    }
  }
  if (cheque == null) return null;

  return PostponedCheque(
    cheque: cheque,
    id: raw['id'],
    createdDate: raw['createdDate'],
    clientId: raw['clientId'] ?? cheque['clientId'],
    clientName: '${raw['clientName'] ?? cheque['clientName'] ?? ''}',
    organizationId: raw['organizationId'] ?? cheque['organizationId'],
    organizationName: '${raw['organizationName'] ?? cheque['organizationName'] ?? ''}',
    agentLogin: '${raw['agentLogin'] ?? ''}',
    agentName: '${raw['agentName'] ?? ''}',
  );
}

/// Ответ сервера → список чеков.
List<PostponedCheque> parsePostponedList(dynamic raw) {
  if (raw is! List) return const [];
  final result = <PostponedCheque>[];
  for (final row in raw) {
    final parsed = parsePostponedRow(row);
    if (parsed != null) result.add(parsed);
  }
  return result;
}

/// Локальный список (`GetStorage`) → список чеков. Формат тот же, что у чека
/// в корзине: обёртки с `id` и `cheque` у офлайновых нет.
List<PostponedCheque> parseStoredList(dynamic raw) {
  if (raw is! List) return const [];
  return [
    for (final row in raw)
      if (row is Map) PostponedCheque(cheque: row, createdDate: row['createdDate']),
  ];
}

/// Совпадает ли валюта отложенного чека с валютой кассы.
///
/// Десктоп на расхождении отказывается открывать чек: суммы позиций посчитаны в
/// той валюте, в которой чек набирали, и пересчитать их касса не может.
bool currencyMatches(Map cheque, dynamic defaultCurrency) {
  final chequeCurrency = customNumber(cheque['currencyId']);
  final cashboxCurrency = customNumber(defaultCurrency);
  // Валюта не проставлена — считаем, что чек кассе подходит: у офлайновых
  // чеков старых версий её могло не быть вовсе.
  if (chequeCurrency == 0 || cashboxCurrency == 0) return true;
  return chequeCurrency == cashboxCurrency;
}

/// Копия чека, не разделяющая с оригиналом ни одной вложенной структуры.
///
/// Не пережилось через JSON (в чеке оказалось что-то не сериализуемое) —
/// возвращаем копию верхнего уровня: потерять чек хуже, чем разделить с ним
/// вложенный список.
Map _deepCopy(Map cheque) {
  try {
    final decoded = jsonDecode(jsonEncode(cheque));
    if (decoded is Map) return decoded;
  } catch (_) {}
  return Map<String, dynamic>.from(cheque);
}

/// Чек из хранилища → чек текущей кассы.
///
/// Отложенный чек мог быть создан вчера, на другой кассе, другим кассиром и в
/// другой смене. Всё, что описывает «кто и когда пробивает», проставляется
/// заново — переносится только корзина и реквизиты покупателя.
///
/// [source] — строка списка: у агентского чека клиент, организация и сам агент
/// лежат рядом с чеком, а не внутри него.
Map<String, dynamic> restorePostponed(
  Map cheque, {
  required Map cashbox,
  required Map user,
  dynamic shiftId,
  PostponedCheque? source,
}) {
  // Глубокая копия, а не ссылка: правки корзины не должны менять чек,
  // оставшийся в списке. Мелочи вроде кодов маркировки лежат вложенными
  // списками, поэтому копии верхнего уровня мало. Чек всегда пришёл из JSON —
  // хранилища или сервера, — так что перегнать его через JSON безопасно.
  final Map original = _deepCopy(cheque);

  final restored = <String, dynamic>{
    for (final entry in original.entries)
      if (!_volatileKeys.contains('${entry.key}')) '${entry.key}': entry.value,
  };

  final items = original['itemsList'];
  if (items is List) {
    final lines = items.map((item) => item is Map ? (item..['selected'] = false) : item).toList();
    if (lines.isNotEmpty && lines.last is Map) {
      (lines.last as Map)['selected'] = true;
    }
    restored['itemsList'] = lines;
  }

  restored['cashboxId'] = cashbox['cashboxId'];
  restored['posId'] = cashbox['posId'];
  restored['posName'] = cashbox['posName'];
  restored['shiftId'] = shiftId ?? cashbox['id'];
  restored['cashierName'] = '${user['firstName'] ?? ''}';
  restored['cashierLogin'] = user['login'];
  restored['login'] = user['login'];
  restored['currencyId'] = cashbox['defaultCurrency'];
  restored['saleCurrencyId'] = cashbox['defaultCurrency'];
  restored['currencyName'] = cashbox['defaultCurrency'] == 2 ? 'USD' : "So'm";
  restored['selectOnSale'] = false;

  if (source != null) {
    // Реквизиты из строки списка перебивают то, что лежало в самом чеке:
    // у агентского чека внутри их может не быть вовсе.
    if (source.clientId != null) restored['clientId'] = source.clientId;
    if (source.clientName.isNotEmpty) restored['clientName'] = source.clientName;
    if (source.organizationId != null) restored['organizationId'] = source.organizationId;
    if (source.organizationName.isNotEmpty) {
      restored['organizationName'] = source.organizationName;
    }
    if (source.agentLogin.isNotEmpty) restored['agentLogin'] = source.agentLogin;
    if (source.agentName.isNotEmpty) restored['agentName'] = source.agentName;

    // Связь «этот чек = та строка на сервере»: продажа с `chequeOnlineId`
    // закрывает исходный чек в облаке. У офлайнового чека id нет — и не должно
    // быть, иначе продажа удалила бы чужую строку.
    if (source.id != null) restored['chequeOnlineId'] = source.id;
  }

  return restored;
}

/// Когда отложили — «дд.ММ ЧЧ:мм».
///
/// Формат приходит разный: офлайновый чек хранит миллисекунды, серверный —
/// строку. Разобрать не удалось — возвращаем пустую строку: дата в списке
/// подсказка, а не реквизит, и падать из-за неё незачем.
String postponedDateLabel(dynamic raw) {
  if (raw == null || raw == '') return '';

  DateTime? date;
  if (raw is num) {
    date = DateTime.fromMillisecondsSinceEpoch(raw.toInt());
  } else {
    final millis = int.tryParse('$raw');
    date = millis != null
        ? DateTime.fromMillisecondsSinceEpoch(millis)
        : DateTime.tryParse('$raw');
  }
  if (date == null) return '';
  return DateFormat('dd.MM HH:mm').format(date.toLocal());
}
